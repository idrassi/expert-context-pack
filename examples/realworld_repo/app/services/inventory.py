from app.models import InventoryItem


class InventoryService:
    def __init__(self) -> None:
        self._items: dict[str, InventoryItem] = {}

    def add_item(self, item: InventoryItem) -> None:
        self._items[item.sku] = item

    def get_stock(self, sku: str) -> dict:
        item = self._items.get(sku)
        if not item:
            return {"sku": sku, "available": 0}
        return {"sku": item.sku, "available": item.quantity}

    def reserve(self, sku: str, quantity: int) -> bool:
        item = self._items.get(sku)
        if not item or item.quantity < quantity:
            return False
        item.quantity -= quantity
        return True
