import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";
import I18n from "I18n";

createWidget("upvotes-comment-composer", {
  tagName: "div.upvotes-comment-composer",
  buildKey: (attrs) => `upvotes-comment-composer-${attrs.id}`,

  defaultState(attrs) {
    return { value: attrs.raw || "" };
  },

  html(attrs, state) {
    const result = [];

    result.push(h("textarea.upvotes-comment-composer-textarea", state.value));

    if (state.value.length > 0) {
      if (state.value.length < this.siteSettings.min_post_length) {
        result.push(
          h(
            "div.upvotes-comment-composer-flash.error",
            I18n.t("upvotes.post.upvotes_comment.composer.too_short", {
              count: this.siteSettings.min_post_length,
            })
          )
        );
      } else if (
        state.value.length < this.siteSettings.upvotes_comment_max_raw_length
      ) {
        result.push(
          h(
            "div.upvotes-comment-composer-flash",
            I18n.t("upvotes.post.upvotes_comment.composer.length_ok", {
              count:
                this.siteSettings.upvotes_comment_max_raw_length -
                state.value.length,
            })
          )
        );
      } else if (
        state.value.length > this.siteSettings.upvotes_comment_max_raw_length
      ) {
        result.push(
          h(
            "div.upvotes-comment-composer-flash.error",
            I18n.t("upvotes.post.upvotes_comment.composer.too_long", {
              count: this.siteSettings.upvotes_comment_max_raw_length,
            })
          )
        );
      }
    }

    return result;
  },

  input(e) {
    this.state.value = e.target.value;
    this.sendWidgetAction("updateValue", this.state.value);
  },
});
