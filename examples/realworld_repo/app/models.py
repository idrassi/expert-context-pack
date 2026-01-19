from dataclasses import dataclass, field
from typing import List


@dataclass
class InventoryItem:
    sku: str
    name: str
    quantity: int


@dataclass
class OrderLine:
    sku: str
    quantity: int
    unit_price: float


@dataclass
class Order:
    order_id: str
    customer_email: str
    status: str
    lines: List[OrderLine] = field(default_factory=list)
