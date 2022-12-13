import {
  acceptance,
} from "discourse/tests/helpers/qunit-helpers";
import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import pretender from "discourse/tests/helpers/create-pretender";

acceptance("Category Edit", function (needs) {
  needs.user();
  needs.settings({ qa_enabled: true });

  test("Editing the category", async function (assert) {
    await visit("/c/bug/edit/settings");
    await click("#create-as-post-voting-default");

    await click("#save-category");

    const payload = JSON.parse(
      pretender.handledRequests[pretender.handledRequests.length - 1]
        .requestBody
    );
    assert.ok(payload.custom_fields.create_as_qa_default);
  });
});
