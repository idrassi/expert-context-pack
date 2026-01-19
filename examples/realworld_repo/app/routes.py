from app.config import Config
from app.services.inventory import InventoryService
from app.services.orders import OrderService


class Router:
    def __init__(self) -> None:
        self.inventory = InventoryService()
        self.orders = OrderService(self.inventory)
        self.config: Config | None = None

    def configure(self, config: Config) -> None:
        self.config = config

    def start(self) -> None:
        # Placeholder for routing table registration.
        pass

    def post_order(self, payload: dict) -> dict:
        return self.orders.place_order(payload)

    def get_inventory(self, sku: str) -> dict:
        return self.inventory.get_stock(sku)
