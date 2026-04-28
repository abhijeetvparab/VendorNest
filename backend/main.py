from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import inspect as sa_inspect, text
from routers import auth_router, users_router, vendors_router
from product_management import models as product_models
from product_management.router import router as products_router
from database import engine

product_models.Base.metadata.create_all(bind=engine)

# Migrate products table: unit/type → units (JSON)
with engine.begin() as _conn:
    try:
        _inspector = sa_inspect(engine)
        if "products" in _inspector.get_table_names():
            _cols = {c["name"] for c in _inspector.get_columns("products")}
            if "unit" in _cols and "units" not in _cols:
                _conn.execute(text("ALTER TABLE products ADD COLUMN units JSON"))
                _conn.execute(text("UPDATE products SET units = JSON_ARRAY(unit)"))
                _conn.execute(text("ALTER TABLE products DROP COLUMN unit"))
            if "type" in _cols:
                _conn.execute(text("ALTER TABLE products DROP COLUMN type"))
    except Exception as _e:
        print(f"[migration] products: {_e}")

# Migrate vendor_profiles table: add pincode column
with engine.begin() as _conn:
    try:
        _inspector = sa_inspect(engine)
        if "vendor_profiles" in _inspector.get_table_names():
            _cols = {c["name"] for c in _inspector.get_columns("vendor_profiles")}
            if "pincode" not in _cols:
                _conn.execute(text("ALTER TABLE vendor_profiles ADD COLUMN pincode VARCHAR(10)"))
    except Exception as _e:
        print(f"[migration] vendor_profiles: {_e}")

app = FastAPI(
    title       = "VendorNest API",
    version     = "1.0.0",
    description = "Vendor Management Platform — HLD v1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins  = ["*"],
    allow_methods  = ["*"],
    allow_headers  = ["*"],
)

app.include_router(auth_router.router)
app.include_router(users_router.router)
app.include_router(vendors_router.router)
app.include_router(products_router)


@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "app": "VendorNest API", "version": "1.0.0", "docs": "/docs"}


@app.get("/health", tags=["Health"])
def health():
    return {"status": "healthy"}
