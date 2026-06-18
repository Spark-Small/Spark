# Triage Labels

The [mattpocock/skills](https://github.com/mattpocock/skills) triage skill speaks in terms of five canonical roles. This file maps those roles to label strings used in Spark-Small/Spark.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this table.

Edit the right-hand column if Spark adopts different GitHub label names.

## Bootstrap labels (one-time)

If these labels do not exist on the repo yet, create them once:

```bash
for label in needs-triage needs-info ready-for-agent ready-for-human wontfix; do
  gh label create "$label" --force 2>/dev/null || true
done
```

Or add them in GitHub → Issues → Labels.
