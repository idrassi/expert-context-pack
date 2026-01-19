from app.config import load_config
from app.logging import configure_logging
from app.routes import Router


class App:
    def __init__(self) -> None:
        self.router = Router()

    def run(self, host: str, port: int, debug: bool = False) -> None:
        configure_logging(debug)
        print(f"Running on {host}:{port} debug={debug}")
        self.router.start()


def create_app() -> App:
    config = load_config()
    app = App()
    app.router.configure(config)
    return app
