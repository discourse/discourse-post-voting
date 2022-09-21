import I18n from "I18n";
import { withPluginApi } from "discourse/lib/plugin-api";
import { CREATE_TOPIC } from "discourse/models/composer";
import { observes } from "discourse-common/utils/decorators";

export default {
  name: "extend-composer-actions",
  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");

    if (!siteSettings.upvotes_enabled) {
      return;
    }

    withPluginApi("0.13.0", (api) => {
      api.serializeOnCreate("create_as_upvotes", "createAsupvotes");

      api.customizeComposerText({
        actionTitle(model) {
          if (model.createAsupvotes) {
            return I18n.t("composer.create_upvotes.label");
          } else if (model.topic?.is_upvotes) {
            return I18n.t("upvotes.topic.answer.label");
          } else {
            return null;
          }
        },

        saveLabel(model) {
          if (model.createAsupvotes) {
            return "composer.create_upvotes.label";
          } else if (model.topic?.is_upvotes) {
            return "upvotes.topic.answer.label";
          } else {
            return null;
          }
        },
      });

      api.modifyClass("component:composer-actions", {
        pluginId: "discourse-upvotes",

        toggleupvotesSelected(options, model) {
          model.toggleProperty("createAsupvotes");
          model.notifyPropertyChange("replyOptions");
          model.notifyPropertyChange("action");
        },
      });

      api.modifySelectKit("composer-actions").appendContent((options) => {
        if (options.action === CREATE_TOPIC) {
          if (options.composerModel.createAsupvotes) {
            return [
              {
                name: I18n.t(
                  "composer.composer_actions.remove_as_upvotes.label"
                ),
                description: I18n.t(
                  "composer.composer_actions.remove_as_upvotes.desc"
                ),
                icon: "plus",
                id: "toggleupvotes",
              },
            ];
          } else {
            return [
              {
                name: I18n.t(
                  "composer.composer_actions.create_as_upvotes.label"
                ),
                description: I18n.t(
                  "composer.composer_actions.create_as_upvotes.desc"
                ),
                icon: "plus",
                id: "toggleupvotes",
              },
            ];
          }
        } else {
          return [];
        }
      });

      api.modifyClass("model:composer", {
        pluginId: "discourse-upvotes",

        @observes("categoryId")
        categoryCreateAsupvotesDefault() {
          const createAsupvotes = this.category?.create_as_upvotes_default;

          if (this.creatingTopic && createAsupvotes !== this.createAsupvotes) {
            this.set("createAsupvotes", createAsupvotes);
            this.notifyPropertyChange("replyOptions");
            this.notifyPropertyChange("action");
          }
        },
      });
    });
  },
};
