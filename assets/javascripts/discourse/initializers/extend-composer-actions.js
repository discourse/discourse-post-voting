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
      api.serializeOnCreate(
        "only_post_voting_in_this_category",
        "onlyPostVotingInThisCategory"
      );

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
          debugger;
          if (
            options.composerModel.createAsPostVoting &&
            !options.composerModel.onlyPostVotingInThisCategory
          ) {
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

          const onlyPostVotingInThisCategory =
            this.category?.only_post_voting_in_this_category;
          debugger;

          if (this.creatingTopic && onlyPostVotingInThisCategory) {
            this.set("createAsPostVoting", true);
            this.set(
              "onlyPostVotingInThisCategory",
              onlyPostVotingInThisCategory
            );
          } else if (
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
