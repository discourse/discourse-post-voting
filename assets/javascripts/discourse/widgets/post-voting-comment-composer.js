import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";
import I18n from "I18n";

createWidget("post-voting-comment-composer", {
  tagName: "div.post-voting-comment-composer",
  buildKey: (attrs) => `post-voting-comment-composer-${attrs.id}`,

  defaultState(attrs) {
    return { value: attrs.raw || "" };
  },

  html(attrs, state) {
    const result = [];

    result.push(
      h("textarea.post-voting-comment-composer-textarea", state.value)
    );

    if (state.value.length > 0) {
      if (state.value.length < this.siteSettings.min_post_length) {
        result.push(
          h(
            "div.post-voting-comment-composer-flash.error",
            I18n.t("post_voting.post.post_voting_comment.composer.too_short", {
              count: this.siteSettings.min_post_length,
            })
          )
        );
      } else if (
        state.value.length < this.siteSettings.qa_comment_max_raw_length
      ) {
        result.push(
          h(
            "div.post-voting-comment-composer-flash",
            I18n.t("post_voting.post.post_voting_comment.composer.length_ok", {
              count:
                this.siteSettings.qa_comment_max_raw_length -
                state.value.length,
            })
          )
        );
      } else if (
        state.value.length > this.siteSettings.qa_comment_max_raw_length
      ) {
        result.push(
          h(
            "div.post-voting-comment-composer-flash.error",
            I18n.t("post_voting.post.post_voting_comment.composer.too_long", {
              count: this.siteSettings.qa_comment_max_raw_length,
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
