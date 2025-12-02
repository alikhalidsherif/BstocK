from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from ..events import hub
from .. import auth, crud
from ..database import SessionLocal

router = APIRouter(prefix="/ws", tags=["realtime"])


@router.websocket("/updates")
async def websocket_updates(websocket: WebSocket):
    # Simple token-based auth via query parameter for WebSocket
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=4401)
        return

    db = SessionLocal()
    try:
        try:
            payload = auth.jwt.decode(token, auth.settings.SECRET_KEY, algorithms=[auth.settings.JWT_ALGORITHM])
            username = payload.get("sub")
            if not username:
                await websocket.close(code=4401)
                return
            user = crud.get_user_by_username(db, username=username)
            if not user or not user.is_active:
                await websocket.close(code=4403)
                return
        except auth.JWTError:
            await websocket.close(code=4401)
            return

        await hub.connect(websocket)
        try:
            while True:
                # Keep the connection alive; we do not expect messages from client
                await websocket.receive_text()
        except WebSocketDisconnect:
            hub.disconnect(websocket)
    finally:
        db.close()


