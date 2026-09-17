"""Non-interactive Python API. The legacy CLI keeps its interactive defaults."""

from .controllers.processor_controller import ProcessorController
from .utils.user_interaction import ConflictResolution


class _QuietConsole:
    def __getattr__(self, name):
        if name.startswith("print_"):
            return lambda *args, **kwargs: None
        raise AttributeError(name)


def process_archive(
    zip_path, config_path=None, *, output_dir=None, on_conflict="counter"
):
    """Return a ProcessingResult without printing or reading stdin.

    on_conflict: ``counter`` preserves existing files; ``cancel`` returns a failed
    result when an output already exists. Invalid configuration raises an error.
    output_dir must exist. The input archive is not modified.
    """
    policies = {
        "counter": ConflictResolution.ADD_COUNTER,
        "cancel": ConflictResolution.CANCEL,
    }
    if on_conflict not in policies:
        raise ValueError("on_conflict must be 'counter' or 'cancel'")
    return ProcessorController(
        str(zip_path),
        str(config_path) if config_path else None,
        output_dir=str(output_dir) if output_dir else None,
        conflict_resolution=policies[on_conflict],
        console=_QuietConsole(),
        strict_config=True,
    ).process()
