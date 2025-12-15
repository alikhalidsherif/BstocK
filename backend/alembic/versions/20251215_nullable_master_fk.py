"""Allow nullable reviewer/requester references and enforce SET NULL."""

from alembic import op
import sqlalchemy as sa


revision = "20251215_nullable_master_fk"
down_revision = None
branch_labels = None
depends_on = None


def _get_fk_names(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    names = set()
    for fk in inspector.get_foreign_keys(table_name):
        name = fk.get("name")
        if name:
            names.add(name)
    return names


def upgrade() -> None:
    # change_requests requester/approver
    existing_fks = _get_fk_names("change_requests")
    with op.batch_alter_table("change_requests", schema=None) as batch_op:
        if "change_requests_requester_id_fkey" in existing_fks:
            batch_op.drop_constraint("change_requests_requester_id_fkey", type_="foreignkey")
        if "change_requests_approver_id_fkey" in existing_fks:
            batch_op.drop_constraint("change_requests_approver_id_fkey", type_="foreignkey")

        batch_op.alter_column(
            "requester_id",
            existing_type=sa.Integer(),
            nullable=True,
        )
        batch_op.alter_column(
            "approver_id",
            existing_type=sa.Integer(),
            nullable=True,
        )

        batch_op.create_foreign_key(
            "fk_change_requests_requester_id",
            "users",
            ["requester_id"],
            ["id"],
            ondelete="SET NULL",
        )
        batch_op.create_foreign_key(
            "fk_change_requests_approver_id",
            "users",
            ["approver_id"],
            ["id"],
            ondelete="SET NULL",
        )

    # change_history requester/reviewer
    existing_fks = _get_fk_names("change_history")
    with op.batch_alter_table("change_history", schema=None) as batch_op:
        if "change_history_requester_id_fkey" in existing_fks:
            batch_op.drop_constraint("change_history_requester_id_fkey", type_="foreignkey")
        if "change_history_reviewer_id_fkey" in existing_fks:
            batch_op.drop_constraint("change_history_reviewer_id_fkey", type_="foreignkey")

        batch_op.alter_column(
            "requester_id",
            existing_type=sa.Integer(),
            nullable=True,
        )
        batch_op.alter_column(
            "reviewer_id",
            existing_type=sa.Integer(),
            nullable=True,
        )

        batch_op.create_foreign_key(
            "fk_change_history_requester_id",
            "users",
            ["requester_id"],
            ["id"],
            ondelete="SET NULL",
        )
        batch_op.create_foreign_key(
            "fk_change_history_reviewer_id",
            "users",
            ["reviewer_id"],
            ["id"],
            ondelete="SET NULL",
        )


def downgrade() -> None:
    with op.batch_alter_table("change_history", schema=None) as batch_op:
        batch_op.drop_constraint("fk_change_history_requester_id", type_="foreignkey")
        batch_op.drop_constraint("fk_change_history_reviewer_id", type_="foreignkey")
        batch_op.alter_column(
            "requester_id",
            existing_type=sa.Integer(),
            nullable=False,
        )
        batch_op.alter_column(
            "reviewer_id",
            existing_type=sa.Integer(),
            nullable=False,
        )
        batch_op.create_foreign_key(
            "change_history_requester_id_fkey",
            "users",
            ["requester_id"],
            ["id"],
        )
        batch_op.create_foreign_key(
            "change_history_reviewer_id_fkey",
            "users",
            ["reviewer_id"],
            ["id"],
        )

    with op.batch_alter_table("change_requests", schema=None) as batch_op:
        batch_op.drop_constraint("fk_change_requests_requester_id", type_="foreignkey")
        batch_op.drop_constraint("fk_change_requests_approver_id", type_="foreignkey")
        batch_op.alter_column(
            "requester_id",
            existing_type=sa.Integer(),
            nullable=False,
        )
        batch_op.alter_column(
            "approver_id",
            existing_type=sa.Integer(),
            nullable=False,
        )
        batch_op.create_foreign_key(
            "change_requests_requester_id_fkey",
            "users",
            ["requester_id"],
            ["id"],
        )
        batch_op.create_foreign_key(
            "change_requests_approver_id_fkey",
            "users",
            ["approver_id"],
            ["id"],
        )

