import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "post-voting-icon",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    if (!siteSettings.post_voting_enabled) {
      return;
    }

    withPluginApi("1.2.0", (api) => {
      api.replaceIcon("notification.question_answer_user_commented", "comment");
    });
  },
};
