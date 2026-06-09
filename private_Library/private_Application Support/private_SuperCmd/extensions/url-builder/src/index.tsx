import { execSync } from "child_process";
import { readFileSync } from "fs";
import { join } from "path";
import { Action, ActionPanel, Form, List } from "@raycast/api";
import { useState } from "react";

type Param = { label: string; placeholder: string };
type Template = { name: string; description: string; url: string; params: Param[] };

const templatesPath = join(
  process.env.HOME ?? "/Users/unknown",
  "Library/Application Support/SuperCmd/extensions/url-builder/url-templates.json"
);

let templates: Template[] = [];
try {
  templates = JSON.parse(readFileSync(templatesPath, "utf-8"));
} catch {
  // missing or malformed file — show empty list
}

function openUrl(url: string): void {
  const safeUrl = url.replace(/'/g, "'\\''").replace(/"/g, '\\"');
  const script = `
    tell application "Google Chrome"
      repeat with w in windows
        set i to 1
        repeat with t in tabs of w
          if URL of t is "${safeUrl}" then
            set active tab index of w to i
            set index of w to 1
            activate
            return true
          end if
          set i to i + 1
        end repeat
      end repeat
      return false
    end tell
  `;
  try {
    const focused = execSync(`osascript -e '${script}'`, { timeout: 5000 }).toString().trim() === "true";
    if (!focused) {
      execSync(`open "${safeUrl}"`);
    }
  } catch {
    execSync(`open "${safeUrl.replace(/"/g, '\\"')}"`);
  }
}

function buildUrl(template: Template, values: Record<string, string>): string {
  return template.url.replace(/\{(\d+)\}/g, (_, i) => encodeURIComponent(values[`param_${i}`] ?? ""));
}

function TemplateForm({ template, onBack }: { template: Template; onBack: () => void }) {
  const [errors, setErrors] = useState<Record<string, string>>({});

  return (
    <Form
      actions={
        <ActionPanel>
          <Action.SubmitForm
            title="Open URL"
            shortcut={{ modifiers: [], key: "return" }}
            onSubmit={(values) => {
              const newErrors: Record<string, string> = {};
              template.params.forEach((_, i) => {
                if (!values[`param_${i}`]) newErrors[`param_${i}`] = "Required";
              });
              if (Object.keys(newErrors).length > 0) {
                setErrors(newErrors);
                return;
              }
              openUrl(buildUrl(template, values as Record<string, string>));
            }}
          />
          <Action title="Back" onAction={onBack} />
        </ActionPanel>
      }
    >
      <Form.Description title={template.name} text={template.description} />
      {template.params.map((param, i) => (
        <Form.TextField
          key={param.label}
          id={`param_${i}`}
          title={param.label}
          placeholder={param.placeholder}
          autoFocus={i === 0}
          error={errors[`param_${i}`]}
          onChange={() => {
            if (errors[`param_${i}`]) {
              setErrors((prev) => {
                const next = { ...prev };
                delete next[`param_${i}`];
                return next;
              });
            }
          }}
        />
      ))}
    </Form>
  );
}

export default function Command() {
  const [selected, setSelected] = useState<Template | null>(null);

  if (selected) {
    return <TemplateForm template={selected} onBack={() => setSelected(null)} />;
  }

  return (
    <List searchBarPlaceholder="Search URL templates...">
      {templates.map((template) => (
        <List.Item
          key={template.name}
          title={template.name}
          subtitle={template.description}
          actions={
            <ActionPanel>
              <Action
                title={template.params.length === 0 ? "Open URL" : "Fill Parameters"}
                onAction={() => {
                  if (template.params.length === 0) {
                    openUrl(template.url);
                  } else {
                    setSelected(template);
                  }
                }}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
