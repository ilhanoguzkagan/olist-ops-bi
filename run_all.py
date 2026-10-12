"""Run the full pipeline: download data -> build warehouse -> KPIs -> dashboard -> Excel pack."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "scripts"))

import build_dashboard  # noqa: E402
import build_warehouse  # noqa: E402
import download_data  # noqa: E402
import export_excel  # noqa: E402
import kpis  # noqa: E402

for step in (download_data, build_warehouse, kpis, build_dashboard, export_excel):
    print(f"\n== {step.__name__}")
    step.main()
print("\nDone. Open dashboard/index.html")
