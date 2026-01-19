from app.models import InventoryItem
from app.services.inventory import InventoryService
from app.services.orders import OrderService


def test_place_order_success() -> None:
    inventory = InventoryService()
    inventory.add_item(InventoryItem(sku="SKU-001", name="Widget", quantity=10))
    orders = OrderService(inventory)
    payload = {"email": "buyer@example.com", "lines": [{"sku": "SKU-001", "quantity": 2, "unit_price": 4.5}]}
    result = orders.place_order(payload)
    assert result["status"] == "accepted"


def test_place_order_rejected() -> None:
    inventory = InventoryService()
    orders = OrderService(inventory)
    payload = {"email": "buyer@example.com", "lines": [{"sku": "SKU-001", "quantity": 2, "unit_price": 4.5}]}
    result = orders.place_order(payload)
    assert result["status"] == "rejected"
