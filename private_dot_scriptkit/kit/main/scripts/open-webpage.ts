import { $ } from "bun"

try {
  await $`open https://engconf.int.kronos.com/spaces/AI/pages/1128693890/Bryte+2.0`
} catch (err) {
  console.error("Failed to open webpage:", err)
}
