from __future__ import annotations

from dataclasses import dataclass
import json
from typing import Iterable


@dataclass(frozen=True)
class Product:
    id: str
    name: str
    price: float
    tags: tuple[str, ...]

    def to_dict(self) -> dict[str, object]:
        return {
            "id": self.id,
            "name": self.name,
            "price": self.price,
            "tags": list(self.tags),
        }

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), indent=2)


def sample_product(tags: Iterable[str] | None = None) -> Product:
    return Product(
        id="demo-001",
        name="Hello Widget",
        price=19.99,
        tags=tuple(tags) if tags is not None else ("demo", "hello", "poc"),
    )
