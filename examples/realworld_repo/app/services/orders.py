from app.models import Order, OrderLine
from app.services.inventory import InventoryService
from app.utils import new_id


class OrderService:
    def __init__(self, inventory: InventoryService) -> None:
        self.inventory = inventory
        self._orders: dict[str, Order] = {}

    def place_order(self, payload: dict) -> dict:
        order_id = new_id("order")
        lines = [OrderLine(**line) for line in payload.get("lines", [])]
        for line in lines:
            if not self.inventory.reserve(line.sku, line.quantity):
                return {"status": "rejected", "reason": "insufficient_stock"}
        order = Order(order_id=order_id, customer_email=payload.get("email", ""), status="created", lines=lines)
        self._orders[order_id] = order
        return {"status": "accepted", "order_id": order_id}

    def get_order(self, order_id: str) -> Order | None:
        return self._orders.get(order_id)
