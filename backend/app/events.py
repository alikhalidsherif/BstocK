from __future__ import annotations

from typing import Set, Any, Dict
import json

from fastapi import WebSocket
import anyio


class WebSocketHub:
    def __init__(self) -> None:
        self._connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket) -> None:
        await websocket.accept()
        self._connections.add(websocket)

    def disconnect(self, websocket: WebSocket) -> None:
        self._connections.discard(websocket)

    async def broadcast_json(self, message: Dict[str, Any]) -> None:
        dead: Set[WebSocket] = set()
        for ws in list(self._connections):
            try:
                await ws.send_text(json.dumps(message))
            except Exception:
                dead.add(ws)
        for ws in dead:
            self.disconnect(ws)

    # Safe to call from normal (threadpool) code
    def publish_from_thread(self, message: Dict[str, Any]) -> None:
        anyio.from_thread.run(self.broadcast_json, message)


hub = WebSocketHub()


