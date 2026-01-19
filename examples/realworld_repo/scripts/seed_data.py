from app.models import InventoryItem
from app.services.inventory import InventoryService


def seed_inventory(service: InventoryService) -> None:
    service.add_item(InventoryItem(sku="SKU-001", name="Widget", quantity=25))
    service.add_item(InventoryItem(sku="SKU-002", name="Gadget", quantity=40))


if __name__ == "__main__":
    inventory = InventoryService()
    seed_inventory(inventory)
    print("Seeded", inventory.get_stock("SKU-001"))
