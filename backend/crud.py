
# crud.py
# Contains functions for Create, Read, Update, Delete (CRUD) operations.

from sqlalchemy.orm import Session
import models
import schemas
import auth # For password hashing

# --- User CRUD ---
def get_user(db: Session, user_id: int):
    """Retrieve a single user by their ID."""
    return db.query(models.User).filter(models.User.id == user_id).first()

def get_user_by_email(db: Session, email: str):
    """Retrieve a single user by their email address."""
    return db.query(models.User).filter(models.User.email == email).first()

def get_users(db: Session, skip: int = 0, limit: int = 100):
    """Retrieve a list of users with pagination."""
    return db.query(models.User).offset(skip).limit(limit).all()

def create_user(db: Session, user: schemas.UserCreate):
    """Create a new user in the database."""
    hashed_password = auth.get_password_hash(user.password)
    db_user = models.User(email=user.email, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# --- Income CRUD ---
def create_user_income(db: Session, income: schemas.IncomeCreate, user_id: int):
    """Create an income transaction for a specific user."""
    db_income = models.Income(**income.model_dump(), owner_id=user_id) # Pydantic v2: income.model_dump()
    # For Pydantic v1: db_income = models.Income(**income.dict(), owner_id=user_id)
    db.add(db_income)
    db.commit()
    db.refresh(db_income)
    return db_income

def get_incomes_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    """Retrieve income transactions for a specific user with pagination."""
    query = db.query(models.Income).filter(models.Income.owner_id == user_id).order_by(models.Income.date.desc())
    if limit > 0 : # if limit is 0, fetch all
        query = query.offset(skip).limit(limit)
    return query.all()


# --- Expense CRUD ---
def create_user_expense(db: Session, expense: schemas.ExpenseCreate, user_id: int):
    """Create an expense transaction for a specific user."""
    db_expense = models.Expense(**expense.model_dump(), owner_id=user_id) # Pydantic v2: expense.model_dump()
    # For Pydantic v1: db_expense = models.Expense(**expense.dict(), owner_id=user_id)
    db.add(db_expense)
    db.commit()
    db.refresh(db_expense)
    return db_expense

def get_expenses_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    """Retrieve expense transactions for a specific user with pagination."""
    query = db.query(models.Expense).filter(models.Expense.owner_id == user_id).order_by(models.Expense.date.desc())
    if limit > 0 : # if limit is 0, fetch all
        query = query.offset(skip).limit(limit)
    return query.all()