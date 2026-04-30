import sys, os
sys.path.insert(0, os.path.dirname(__file__))

import pytest
from conftest import auth_header
from models import UserRole, UserStatus, VendorProfile, OnboardingStatus

# ── Shared helpers ────────────────────────────────────────────────────────────

ONBOARDING_PAYLOAD = {
    "business_name":    "Test Electronics Hub",
    "business_type":    "Electronics",
    "business_address": "22 Vendor Street City",
    "poc_name":         "Victor Vendor",
    "poc_phone":        "9876543210",
    "poc_email":        "victor@ehub.com",
    "description":      "Premium electronics.",
}


def make_profile(db, vendor_user, **overrides):
    """Create a VendorProfile directly in the DB, bypassing the API."""
    defaults = {
        "business_name":    "Test Business",
        "business_type":    "Electronics",
        "business_address": "22 Vendor Street City",
        "poc_name":         "Test POC",
        "poc_phone":        "9876543210",
        "poc_email":        "poc@business.com",
    }
    defaults.update(overrides)
    profile = VendorProfile(user_id=vendor_user.id, **defaults)
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


# ── Submit Onboarding ─────────────────────────────────────────────────────────

class TestSubmitOnboarding:
    def test_vendor_can_submit_onboarding(self, client, db, make_user):
        vendor = make_user(db, email="v@test.com",
                           role=UserRole.VENDOR, status=UserStatus.PENDING)
        r = client.post("/api/vendors/onboarding",
                        json=ONBOARDING_PAYLOAD, headers=auth_header(vendor))
        assert r.status_code == 201
        data = r.json()
        assert data["business_name"]    == "Test Electronics Hub"
        assert data["onboarding_status"] == "Pending"

    def test_submitted_profile_linked_to_vendor(self, client, db, make_user):
        vendor = make_user(db, email="v@test.com",
                           role=UserRole.VENDOR, status=UserStatus.PENDING)
        r = client.post("/api/vendors/onboarding",
                        json=ONBOARDING_PAYLOAD, headers=auth_header(vendor))
        assert r.json()["user_id"] == vendor.id

    def test_non_vendor_cannot_submit(self, client, db, make_user):
        customer = make_user(db, email="cust@test.com")
        r = client.post("/api/vendors/onboarding",
                        json=ONBOARDING_PAYLOAD, headers=auth_header(customer))
        assert r.status_code == 403
        assert "vendors" in r.json()["detail"].lower()

    def test_admin_cannot_submit_onboarding(self, client, db, make_user):
        admin = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        r = client.post("/api/vendors/onboarding",
                        json=ONBOARDING_PAYLOAD, headers=auth_header(admin))
        assert r.status_code == 403

    def test_unauthenticated_is_rejected(self, client):
        r = client.post("/api/vendors/onboarding", json=ONBOARDING_PAYLOAD)
        assert r.status_code in (401, 403)

    def test_resubmission_updates_business_name(self, client, db, make_user):
        vendor = make_user(db, email="v@test.com",
                           role=UserRole.VENDOR, status=UserStatus.PENDING)
        client.post("/api/vendors/onboarding",
                    json=ONBOARDING_PAYLOAD, headers=auth_header(vendor))
        updated = {**ONBOARDING_PAYLOAD, "business_name": "Renamed Business"}
        r = client.post("/api/vendors/onboarding",
                        json=updated, headers=auth_header(vendor))
        assert r.status_code == 201
        assert r.json()["business_name"] == "Renamed Business"

    def test_resubmission_resets_status_to_pending(self, client, db, make_user):
        vendor = make_user(db, email="v@test.com",
                           role=UserRole.VENDOR, status=UserStatus.ACTIVE)
        profile = make_profile(db, vendor,
                               onboarding_status=OnboardingStatus.REJECTED,
                               rejection_reason="Bad docs")
        r = client.post("/api/vendors/onboarding",
                        json=ONBOARDING_PAYLOAD, headers=auth_header(vendor))
        assert r.json()["onboarding_status"] == "Pending"
        assert r.json()["rejection_reason"] is None

    def test_resubmission_creates_only_one_profile(self, client, db, make_user):
        vendor = make_user(db, email="v@test.com",
                           role=UserRole.VENDOR, status=UserStatus.PENDING)
        client.post("/api/vendors/onboarding",
                    json=ONBOARDING_PAYLOAD, headers=auth_header(vendor))
        client.post("/api/vendors/onboarding",
                    json=ONBOARDING_PAYLOAD, headers=auth_header(vendor))
        count = db.query(VendorProfile).filter(
            VendorProfile.user_id == vendor.id).count()
        assert count == 1


# ── List Onboarding (admin) ───────────────────────────────────────────────────

class TestListOnboarding:
    def test_admin_can_list_all_submissions(self, client, db, make_user):
        admin  = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor = make_user(db, email="v@test.com",
                           role=UserRole.VENDOR, status=UserStatus.PENDING)
        make_profile(db, vendor)
        r = client.get("/api/vendors/onboarding", headers=auth_header(admin))
        assert r.status_code == 200
        assert len(r.json()) == 1

    def test_filter_by_pending_status(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor1 = make_user(db, email="v1@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        vendor2 = make_user(db, email="v2@test.com",
                            role=UserRole.VENDOR, status=UserStatus.ACTIVE)
        make_profile(db, vendor1)
        make_profile(db, vendor2, onboarding_status=OnboardingStatus.APPROVED)
        r = client.get("/api/vendors/onboarding?status=Pending",
                       headers=auth_header(admin))
        data = r.json()
        assert len(data) == 1
        assert data[0]["onboarding_status"] == "Pending"

    def test_filter_by_approved_status(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor1 = make_user(db, email="v1@test.com",
                            role=UserRole.VENDOR, status=UserStatus.ACTIVE)
        vendor2 = make_user(db, email="v2@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        make_profile(db, vendor1, onboarding_status=OnboardingStatus.APPROVED)
        make_profile(db, vendor2)
        r = client.get("/api/vendors/onboarding?status=Approved",
                       headers=auth_header(admin))
        data = r.json()
        assert all(p["onboarding_status"] == "Approved" for p in data)

    def test_non_admin_is_forbidden(self, client, db, make_user):
        vendor = make_user(db, email="v@test.com",
                           role=UserRole.VENDOR, status=UserStatus.PENDING)
        r = client.get("/api/vendors/onboarding", headers=auth_header(vendor))
        assert r.status_code == 403

    def test_empty_list_when_no_submissions(self, client, db, make_user):
        admin = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        r = client.get("/api/vendors/onboarding", headers=auth_header(admin))
        assert r.json() == []


# ── Get My Onboarding ─────────────────────────────────────────────────────────

class TestGetMyOnboarding:
    def test_vendor_can_get_own_profile(self, client, db, make_user):
        vendor = make_user(db, email="v@test.com",
                           role=UserRole.VENDOR, status=UserStatus.PENDING)
        make_profile(db, vendor)
        r = client.get("/api/vendors/onboarding/mine", headers=auth_header(vendor))
        assert r.status_code == 200
        assert r.json()["user_id"] == vendor.id

    def test_returns_404_when_no_submission(self, client, db, make_user):
        vendor = make_user(db, email="v@test.com",
                           role=UserRole.VENDOR, status=UserStatus.PENDING)
        r = client.get("/api/vendors/onboarding/mine", headers=auth_header(vendor))
        assert r.status_code == 404

    def test_returns_correct_onboarding_status(self, client, db, make_user):
        vendor = make_user(db, email="v@test.com",
                           role=UserRole.VENDOR, status=UserStatus.ACTIVE)
        make_profile(db, vendor, onboarding_status=OnboardingStatus.APPROVED)
        r = client.get("/api/vendors/onboarding/mine", headers=auth_header(vendor))
        assert r.json()["onboarding_status"] == "Approved"


# ── Get Onboarding by ID ──────────────────────────────────────────────────────

class TestGetOnboardingById:
    def test_admin_can_get_any_profile(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        r = client.get(f"/api/vendors/onboarding/{profile.id}",
                       headers=auth_header(admin))
        assert r.status_code == 200
        assert r.json()["id"] == profile.id

    def test_vendor_can_get_own_profile(self, client, db, make_user):
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        r = client.get(f"/api/vendors/onboarding/{profile.id}",
                       headers=auth_header(vendor))
        assert r.status_code == 200

    def test_vendor_cannot_access_another_vendors_profile(self, client, db, make_user):
        vendor1 = make_user(db, email="v1@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        vendor2 = make_user(db, email="v2@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor2)
        r = client.get(f"/api/vendors/onboarding/{profile.id}",
                       headers=auth_header(vendor1))
        assert r.status_code == 403

    def test_nonexistent_profile_returns_404(self, client, db, make_user):
        admin = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        r = client.get("/api/vendors/onboarding/no-such-id",
                       headers=auth_header(admin))
        assert r.status_code == 404


# ── Approve Vendor ────────────────────────────────────────────────────────────

class TestApproveVendor:
    def test_admin_can_approve_pending_vendor(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        r = client.patch(f"/api/vendors/onboarding/{profile.id}/approve",
                         headers=auth_header(admin))
        assert r.status_code == 200
        assert r.json()["onboarding_status"] == "Approved"

    def test_approve_sets_vendor_user_status_to_active(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        client.patch(f"/api/vendors/onboarding/{profile.id}/approve",
                     headers=auth_header(admin))
        db.refresh(vendor)
        assert vendor.status == UserStatus.ACTIVE

    def test_approve_records_reviewed_by(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        r = client.patch(f"/api/vendors/onboarding/{profile.id}/approve",
                         headers=auth_header(admin))
        assert r.json()["reviewed_by"] == admin.id

    def test_approve_sets_reviewed_at_timestamp(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        r = client.patch(f"/api/vendors/onboarding/{profile.id}/approve",
                         headers=auth_header(admin))
        assert r.json()["reviewed_at"] is not None

    def test_non_admin_cannot_approve(self, client, db, make_user):
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        r = client.patch(f"/api/vendors/onboarding/{profile.id}/approve",
                         headers=auth_header(vendor))
        assert r.status_code == 403

    def test_nonexistent_profile_returns_404(self, client, db, make_user):
        admin = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        r = client.patch("/api/vendors/onboarding/no-such-id/approve",
                         headers=auth_header(admin))
        assert r.status_code == 404


# ── Reject Vendor ─────────────────────────────────────────────────────────────

class TestRejectVendor:
    def test_admin_can_reject_with_reason(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        r = client.patch(f"/api/vendors/onboarding/{profile.id}/reject",
                         json={"reason": "Incomplete documents"},
                         headers=auth_header(admin))
        assert r.status_code == 200
        data = r.json()
        assert data["onboarding_status"] == "Rejected"
        assert data["rejection_reason"]   == "Incomplete documents"

    def test_rejection_records_reviewed_by(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        r = client.patch(f"/api/vendors/onboarding/{profile.id}/reject",
                         json={"reason": "Invalid GST"},
                         headers=auth_header(admin))
        assert r.json()["reviewed_by"] == admin.id

    def test_rejection_sets_reviewed_at_timestamp(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        r = client.patch(f"/api/vendors/onboarding/{profile.id}/reject",
                         json={"reason": "Bad docs"},
                         headers=auth_header(admin))
        assert r.json()["reviewed_at"] is not None

    def test_blank_reason_returns_400(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        r = client.patch(f"/api/vendors/onboarding/{profile.id}/reject",
                         json={"reason": "   "},
                         headers=auth_header(admin))
        assert r.status_code == 400

    def test_reason_stored_stripped_of_whitespace(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        r = client.patch(f"/api/vendors/onboarding/{profile.id}/reject",
                         json={"reason": "  Bad docs  "},
                         headers=auth_header(admin))
        assert r.json()["rejection_reason"] == "Bad docs"

    def test_non_admin_cannot_reject(self, client, db, make_user):
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        r = client.patch(f"/api/vendors/onboarding/{profile.id}/reject",
                         json={"reason": "Denied"},
                         headers=auth_header(vendor))
        assert r.status_code == 403

    def test_nonexistent_profile_returns_404(self, client, db, make_user):
        admin = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        r = client.patch("/api/vendors/onboarding/no-such-id/reject",
                         json={"reason": "Not found"},
                         headers=auth_header(admin))
        assert r.status_code == 404

    def test_rejected_vendor_user_status_unchanged(self, client, db, make_user):
        admin   = make_user(db, email="admin@test.com", role=UserRole.ADMIN)
        vendor  = make_user(db, email="v@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        profile = make_profile(db, vendor)
        client.patch(f"/api/vendors/onboarding/{profile.id}/reject",
                     json={"reason": "Docs missing"},
                     headers=auth_header(admin))
        db.refresh(vendor)
        assert vendor.status == UserStatus.PENDING


# ── List Approved Vendors (public) ────────────────────────────────────────────

class TestListApprovedVendors:
    def test_returns_only_approved_profiles(self, client, db, make_user):
        vendor1 = make_user(db, email="v1@test.com",
                            role=UserRole.VENDOR, status=UserStatus.ACTIVE)
        vendor2 = make_user(db, email="v2@test.com",
                            role=UserRole.VENDOR, status=UserStatus.PENDING)
        make_profile(db, vendor1, onboarding_status=OnboardingStatus.APPROVED)
        make_profile(db, vendor2)
        r = client.get("/api/vendors/approved")
        assert r.status_code == 200
        data = r.json()
        assert len(data) == 1
        assert data[0]["onboarding_status"] == "Approved"

    def test_no_auth_required(self, client):
        r = client.get("/api/vendors/approved")
        assert r.status_code == 200

    def test_empty_list_when_none_approved(self, client):
        r = client.get("/api/vendors/approved")
        assert r.json() == []

    def test_filter_by_business_type(self, client, db, make_user):
        vendor1 = make_user(db, email="v1@test.com",
                            role=UserRole.VENDOR, status=UserStatus.ACTIVE)
        vendor2 = make_user(db, email="v2@test.com",
                            role=UserRole.VENDOR, status=UserStatus.ACTIVE)
        make_profile(db, vendor1, business_type="Electronics",
                     onboarding_status=OnboardingStatus.APPROVED)
        make_profile(db, vendor2, business_type="Clothing",
                     onboarding_status=OnboardingStatus.APPROVED)
        r = client.get("/api/vendors/approved?business_type=Electronics")
        data = r.json()
        assert len(data) == 1
        assert data[0]["business_type"] == "Electronics"

    def test_search_by_business_name(self, client, db, make_user):
        vendor1 = make_user(db, email="v1@test.com",
                            role=UserRole.VENDOR, status=UserStatus.ACTIVE)
        vendor2 = make_user(db, email="v2@test.com",
                            role=UserRole.VENDOR, status=UserStatus.ACTIVE)
        make_profile(db, vendor1, business_name="Alpha Electronics",
                     onboarding_status=OnboardingStatus.APPROVED)
        make_profile(db, vendor2, business_name="Beta Clothing",
                     onboarding_status=OnboardingStatus.APPROVED)
        r = client.get("/api/vendors/approved?search=Alpha")
        data = r.json()
        assert len(data) == 1
        assert data[0]["business_name"] == "Alpha Electronics"

    def test_pending_vendors_excluded_from_approved_list(self, client, db, make_user):
        vendor = make_user(db, email="v@test.com",
                           role=UserRole.VENDOR, status=UserStatus.PENDING)
        make_profile(db, vendor, onboarding_status=OnboardingStatus.PENDING)
        r = client.get("/api/vendors/approved")
        assert r.json() == []
