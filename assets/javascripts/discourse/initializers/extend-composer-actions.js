import I18n from "I18n";
import { withPluginApi } from "discourse/lib/plugin-api";
import { CREATE_TOPIC } from "discourse/models/composer";
import { observes } from "discourse-common/utils/decorators";

export default {
  name: "extend-composer-actions",
  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");

    if (!siteSettings.post_voting_enabled) {
      return;
    }

    withPluginApi("0.13.0", (api) => {
      api.serializeOnCreate("create_as_post_voting", "createAsPostVoting");

      api.customizeComposerText({
        actionTitle(model) {
          if (model.createAsPostVoting) {
            return I18n.t("composer.create_post_voting.label");
          } else if (model.topic?.is_post_voting) {
            return I18n.t("post_voting.topic.answer.label");
          } else {
            return null;
          }
        },

        saveLabel(model) {
          if (model.createAsPostVoting) {
            return "composer.create_post_voting.label";
          } else if (model.topic?.is_post_voting) {
            return "post_voting.topic.answer.label";
          } else {
            return null;
          }
        },
      });

      api.modifyClass("component:composer-actions", {
        pluginId: "discourse-post-voting",

        togglePostVotingSelected(options, model) {
          model.toggleProperty("createAsPostVoting");
          model.notifyPropertyChange("replyOptions");
          model.notifyPropertyChange("action");
        },
      });

      api.modifySelectKit("composer-actions").appendContent((options) => {
        if (options.action === CREATE_TOPIC) {
          if (options.composerModel.createAsPostVoting) {
            return [
              {
                name: I18n.t(
                  "composer.composer_actions.remove_as_post_voting.label"
                ),
                description: I18n.t(
                  "composer.composer_actions.remove_as_post_voting.desc"
                ),
                icon: "plus",
                id: "togglePostVoting",
              },
            ];
          } else {
            return [
              {
                name: I18n.t(
                  "composer.composer_actions.create_as_post_voting.label"
                ),
                description: I18n.t(
                  "composer.composer_actions.create_as_post_voting.desc"
                ),
                icon: "plus",
                id: "togglePostVoting",
              },
            ];
          }
        } else {
          return [];
        }
      });

      api.modifyClass("model:composer", {
        pluginId: "discourse-post-voting",

        @observes("categoryId")
        categoryCreateAsPostVotingDefault() {
          const createAsPostVoting =
            this.category?.create_as_post_voting_default;

          if (
            this.creatingTopic &&
            createAsPostVoting !== this.createAsPostVoting
          ) {
            this.set("createAsPostVoting", createAsPostVoting);
            this.notifyPropertyChange("replyOptions");
            this.notifyPropertyChange("action");
          }
        },
      });
    });
  },
};
