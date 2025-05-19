from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
from datetime import datetime

# --- Base Schemas ---
class TransactionBase(BaseModel):
    description: Optional[str] = None
    amount: float = Field(..., gt=0, description="Amount must be greater than zero")

class Transaction(TransactionBase):
    id: int
    date: datetime
    owner_id: int

    class Config:
        from_attributes = True # For pydantic v2

# --- Income Schemas ---
class IncomeCreate(TransactionBase):
    pass

class Income(Transaction):
    pass

# --- Expense Schemas ---
class ExpenseCreate(TransactionBase):
    category: Optional[str] = None

class Expense(Transaction):
    category: Optional[str] = None

# --- User Schemas ---
class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, description="Password must be at least 8 characters long")

class User(UserBase):
    id: int

    class Config:
        from_attributes = True # For pydantic v2

# --- Token Schemas (for authentication) ---
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[EmailStr] = None

# --- Summary Schema ---
class Summary(BaseModel):
    total_income: float
    total_expenses: float
    balance: float
    incomes: List[Income]
    expenses: List[Expense]

    class Config:
        from_attributes = True # For pydantic v2