from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from ..events import hub
from .. import auth, models

router = APIRouter(prefix="/ws", tags=["realtime"])


@router.websocket("/updates")
async def websocket_updates(websocket: WebSocket):
    await hub.connect(websocket)
    try:
        while True:
            # Keep the connection alive; we do not expect messages from client
            await websocket.receive_text()
    except WebSocketDisconnect:
        hub.disconnect(websocket)


