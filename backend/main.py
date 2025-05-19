# main.py
# Main FastAPI application file

from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Annotated

# Import modules from the current project
import models
import schemas
import crud
import auth
from database import SessionLocal, engine

# Create all database tables (if they don't exist)
# In a production environment, you might use Alembic for migrations
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Budget App API",
    description="API for managing personal income and expenses.",
    version="0.1.0"
)

# Dependency to get a database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Type alias for database session dependency
DbDep = Annotated[Session, Depends(get_db)]
# Type alias for current user dependency
CurrentUserDep = Annotated[schemas.User, Depends(auth.get_current_active_user)]

# --- Authentication Endpoints ---
@app.post("/users/signup", response_model=schemas.User, status_code=status.HTTP_201_CREATED, tags=["Users"])
async def create_user(user: schemas.UserCreate, db: DbDep):
    """
    Create a new user.
    - **email**: User's email address.
    - **password**: User's password (will be hashed).
    """
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.create_user(db=db, user=user)

@app.post("/users/login", response_model=schemas.Token, tags=["Users"])
async def login_for_access_token(form_data: Annotated[auth.OAuth2PasswordRequestForm, Depends()], db: DbDep):
    """
    Authenticate user and return an access token.
    Uses OAuth2PasswordRequestForm, so provide 'username' (email) and 'password'.
    """
    user = auth.authenticate_user(db, email=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = auth.create_access_token(
        data={"sub": user.email}
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me", response_model=schemas.User, tags=["Users"])
async def read_users_me(current_user: CurrentUserDep):
    """
    Get details of the currently authenticated user.
    """
    return current_user

# --- Transaction Endpoints ---
@app.post("/transactions/income", response_model=schemas.Income, status_code=status.HTTP_201_CREATED, tags=["Transactions"])
async def add_income(income: schemas.IncomeCreate, current_user: CurrentUserDep, db: DbDep):
    """
    Add an income transaction for the authenticated user.
    - **description**: Description of the income.
    - **amount**: Amount of income (must be positive).
    """
    if income.amount <= 0:
        raise HTTPException(status_code=400, detail="Income amount must be positive.")
    return crud.create_user_income(db=db, income=income, user_id=current_user.id)

@app.post("/transactions/expense", response_model=schemas.Expense, status_code=status.HTTP_201_CREATED, tags=["Transactions"])
async def add_expense(expense: schemas.ExpenseCreate, current_user: CurrentUserDep, db: DbDep):
    """
    Add an expense transaction for the authenticated user.
    - **description**: Description of the expense.
    - **amount**: Amount of expense (must be positive).
    - **category**: Category of the expense (e.g., Food, Transport).
    """
    if expense.amount <= 0:
        raise HTTPException(status_code=400, detail="Expense amount must be positive.")
    return crud.create_user_expense(db=db, expense=expense, user_id=current_user.id)

@app.get("/transactions/summary", response_model=schemas.Summary, tags=["Transactions"])
async def get_transaction_summary(current_user: CurrentUserDep, db: DbDep, skip: int = 0, limit: int = 100):
    """
    Get a summary of income and expenses for the authenticated user.
    Includes total income, total expenses, and lists of individual transactions.
    Supports pagination for transaction lists.
    """
    incomes = crud.get_incomes_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    expenses = crud.get_expenses_by_user(db, user_id=current_user.id, skip=skip, limit=limit)

    total_income = sum(inc.amount for inc in crud.get_incomes_by_user(db, user_id=current_user.id, skip=0, limit=0)) # Get all for sum
    total_expenses = sum(exp.amount for exp in crud.get_expenses_by_user(db, user_id=current_user.id, skip=0, limit=0)) # Get all for sum
    
    # Adjust crud functions to handle limit=0 as "get all" or create separate functions for totals
    # For simplicity here, we re-fetch all for sum. In production, optimize this.
    all_incomes_for_sum = crud.get_incomes_by_user(db, user_id=current_user.id, skip=0, limit=10000) # Assuming max 10000 incomes for sum
    all_expenses_for_sum = crud.get_expenses_by_user(db, user_id=current_user.id, skip=0, limit=10000) # Assuming max 10000 expenses for sum

    total_income = sum(inc.amount for inc in all_incomes_for_sum)
    total_expenses = sum(exp.amount for exp in all_expenses_for_sum)


    return schemas.Summary(
        total_income=total_income,
        total_expenses=total_expenses,
        balance=total_income - total_expenses,
        incomes=incomes,
        expenses=expenses
    )

@app.get("/transactions/income", response_model=List[schemas.Income], tags=["Transactions"])
async def list_user_incomes(current_user: CurrentUserDep, db: DbDep, skip: int = 0, limit: int = 100):
    """
    Get a list of all income transactions for the authenticated user.
    Supports pagination.
    """
    incomes = crud.get_incomes_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    return incomes

@app.get("/transactions/expenses", response_model=List[schemas.Expense], tags=["Transactions"])
async def list_user_expenses(current_user: CurrentUserDep, db: DbDep, skip: int = 0, limit: int = 100):
    """
    Get a list of all expense transactions for the authenticated user.
    Supports pagination.
    """
    expenses = crud.get_expenses_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    return expenses

# --- Health Check Endpoint ---
@app.get("/health", status_code=status.HTTP_200_OK, tags=["Health"])
async def health_check():
    """
    Simple health check endpoint.
    """
    return {"status": "healthy"}

# To run this app:
# 1. Save this file as main.py
# 2. Ensure other files (models.py, schemas.py, crud.py, auth.py, database.py) are in the same directory.
# 3. Create a .env file with your DB_STRING, SECRET_KEY, etc.
# 4. Install dependencies: pip install -r requirements.txt
# 5. Run with Uvicorn: uvicorn main:app --reload

