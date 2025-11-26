from datetime import timedelta
from typing import Annotated, Any
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from app.core import security
from app.core.config import settings
from app.api.deps import SessionDep, get_current_active_superuser, CurrentUser
from app.models import Message, NewPassword, Token, UserPublic, UserCreate
from app import crud
router = APIRouter(prefix="", tags=["auth"])
@router.post(f"{settings.API_V1_STR}/login/access-token", response_model=Token)
def login_access_token(session: SessionDep, form_data: Annotated[OAuth2PasswordRequestForm, Depends()]) -> Any:
    user = crud.authenticate(session=session, email=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return {
        "access_token": security.create_access_token(user.id, access_token_expires),
        "token_type": "bearer",
    }
@router.post(f"{settings.API_V1_STR}/users/", response_model=UserPublic)
def register_user(session: SessionDep, user_in: UserCreate) -> Any:

    # Debug print du password
    print(
        "=== RECEIVED PASSWORD ===",
        user_in.password.encode("utf-8"),
        len(user_in.password.encode("utf-8"))
    )

    user = crud.create_user(session=session, user_create=user_in)
    return UserPublic(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        is_active=user.is_active,
        is_superuser=user.is_superuser
    )
