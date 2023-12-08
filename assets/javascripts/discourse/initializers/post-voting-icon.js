import { withPluginApi } from "discourse/lib/plugin-api";
import { postUrl } from "discourse/lib/utilities";
import { buildAnchorId } from "../components/post-voting-comment";

export default {
  name: "post-voting-icon",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    if (!siteSettings.post_voting_enabled) {
      return;
    }

    withPluginApi("1.18.0", (api) => {
      if (api.registerNotificationTypeRenderer) {
        api.registerNotificationTypeRenderer(
          "question_answer_user_commented",
          (NotificationTypeBase) => {
            return class extends NotificationTypeBase {
              get linkTitle() {
                return I18n.t(
                  "notifications.titles.question_answer_user_commented"
                );
              }

              get linkHref() {
                const url = postUrl(
                  this.notification.slug,
                  this.topicId,
                  this.notification.post_number
                );
                return `${url}#${buildAnchorId(
                  this.notification.data.post_voting_comment_id
                )}`;
              }

              get icon() {
                return "comment";
              }
            };
          }
        );
      }
    });
  },
};
