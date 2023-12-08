import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import I18n from "I18n";

acceptance("Discourse Post Voting - notifications", function (needs) {
  needs.user();
  needs.settings({ post_voting_enabled: true });

  needs.pretender((server, helper) => {
    server.get("/notifications", () => {
      return helper.response({
        notifications: [
          {
            id: 1,
            user_id: 26,
            notification_type: 35,
            post_number: 1,
            topic_id: 59,
            fancy_title: "some fancy title",
            slug: "some-slug",
            data: {
              display_username: "someuser",
              post_voting_comment_id: 123,
            },
          },
        ],
        total_rows_notifications: 1,
      });
    });
  });

  test("viewing comments notifications", async (assert) => {
    await visit("/u/eviltrout/notifications");

    const notification = query(".user-notifications-list .notification");

    assert.strictEqual(
      notification.querySelector(".item-label").textContent.trim(),
      "someuser",
      "Renders username"
    );

    assert.strictEqual(
      notification.querySelector(".item-description").textContent.trim(),
      "some fancy title",
      "Renders description"
    );

    assert.ok(
      notification
        .querySelector("a")
        .href.includes("/t/some-slug/59#post-voting-comment-123"),
      "displays a link with a hash fragment pointing to the comment id"
    );

    assert.strictEqual(
      notification.querySelector("a").title,
      I18n.t("notifications.titles.question_answer_user_commented"),
      "displays the right title"
    );
  });
});
