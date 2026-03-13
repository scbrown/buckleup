def test_import():
    """Verify the package imports without error."""
    import importlib

    mod = importlib.import_module("{{ project_name }}")
    assert mod is not None
