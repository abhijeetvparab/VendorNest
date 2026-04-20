from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth_router, users_router, vendors_router

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


@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "app": "VendorNest API", "version": "1.0.0", "docs": "/docs"}


@app.get("/health", tags=["Health"])
def health():
    return {"status": "healthy"}
