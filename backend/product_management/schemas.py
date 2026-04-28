from datetime import datetime
from typing import Optional
from pydantic import BaseModel, field_validator


class ProductCreate(BaseModel):
    name:            str
    description:     Optional[str] = None
    units:           list[str]
    is_available:    bool = True
    is_subscribable: bool = False

    @field_validator("name")
    @classmethod
    def name_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Product name cannot be empty")
        return v.strip()

    @field_validator("units")
    @classmethod
    def units_valid(cls, v: list) -> list:
        cleaned = [u.strip() for u in v if u.strip()]
        if not cleaned:
            raise ValueError("At least one unit is required")
        return cleaned

    @field_validator("description")
    @classmethod
    def max_description(cls, v: Optional[str]) -> Optional[str]:
        if v and len(v.strip()) > 500:
            raise ValueError("Description must be 500 characters or fewer")
        return v.strip() if v else None


class ProductUpdate(BaseModel):
    name:            Optional[str]       = None
    description:     Optional[str]       = None
    units:           Optional[list[str]] = None
    is_available:    Optional[bool]      = None
    is_subscribable: Optional[bool]      = None
    is_deleted:      Optional[bool]      = None


class ProductResponse(BaseModel):
    id:              str
    vendor_id:       str
    name:            str
    description:     Optional[str]
    units:           list[str]
    is_available:    bool
    is_subscribable: bool
    is_deleted:      bool
    created_at:      datetime
    updated_at:      datetime

    model_config = {"from_attributes": True}
