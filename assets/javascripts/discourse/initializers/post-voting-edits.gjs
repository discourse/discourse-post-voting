import Component from "@glimmer/component";
import { withSilencedDeprecations } from "discourse/lib/deprecated";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";
import PostVotingAnswerButton from "../components/post-voting-answer-button";
import PostVotingComments from "../components/post-voting-comments";

export const ORDER_BY_ACTIVITY_FILTER = "activity";
const pluginId = "discourse-post-voting";

function initPlugin(api, container) {
  customizePostMenu(api, container);

  api.modifyClass("model:post-stream", {
    pluginId,

    orderStreamByActivity() {
      this.cancelFilter();
      this.set("filter", ORDER_BY_ACTIVITY_FILTER);
      return this.refreshAndJumpToSecondVisible();
    },

    orderStreamByVotes() {
      this.cancelFilter();
      return this.refreshAndJumpToSecondVisible();
    },
  });

  function customLastUnreadUrl(context) {
    if (context.is_post_voting && context.last_read_post_number) {
      if (context.highest_post_number <= context.last_read_post_number) {
        // link to OP if no unread
        return context.urlForPostNumber(1);
      } else if (
        context.last_read_post_number ===
        context.highest_post_number - 1
      ) {
        return context.urlForPostNumber(context.last_read_post_number + 1);
      } else {
        // sort by activity if user has 2+ unread posts
        return `${context.urlForPostNumber(
          context.last_read_post_number + 1
        )}?filter=activity`;
      }
    }
  }

  api.registerCustomLastUnreadUrlCallback(customLastUnreadUrl);

  api.reopenWidget("post", {
    orderByVotes() {
      this._topicController()
        .model.postStream.orderStreamByVotes()
        .then(() => {
          this._refreshController();
        });
    },

    orderByActivity() {
      this._topicController()
        .model.postStream.orderStreamByActivity()
        .then(() => {
          this._refreshController();
        });
    },

    _refreshController() {
      this._topicController().updateQueryParams();
    },

    _topicController() {
      return this.register.lookup("controller:topic");
    },
  });

  api.decorateWidget("post-article:before", (helper) => {
    const result = [];
    const post = helper.getModel();

    if (!post.topic.is_post_voting) {
      return result;
    }

    const topicController = helper.widget.register.lookup("controller:topic");
    let positionInStream;

    if (
      topicController.replies_to_post_number &&
      parseInt(topicController.replies_to_post_number, 10) !== 1
    ) {
      positionInStream = 2;
    } else {
      positionInStream = 1;
    }

    const answersCount = post.topic.posts_count - 1;

    if (
      answersCount <= 0 ||
      post.id !== post.topic.postStream.stream[positionInStream]
    ) {
      return result;
    }

    result.push(
      helper.h("div.post-voting-answers-header.small-action", [
        helper.h(
          "span.post-voting-answers-headers-count",
          i18n("post_voting.topic.answer_count", { count: answersCount })
        ),
        helper.h("span.post-voting-answers-headers-sort", [
          helper.h("span", i18n("post_voting.topic.sort_by")),
          helper.attach("button", {
            action: "orderByVotes",
            contents: i18n("post_voting.topic.votes"),
            disabled: topicController.filter !== ORDER_BY_ACTIVITY_FILTER,
            className: `post-voting-answers-headers-sort-votes ${
              topicController.filter === ORDER_BY_ACTIVITY_FILTER
                ? ""
                : "active"
            }`,
          }),
          helper.attach("button", {
            action: "orderByActivity",
            contents: i18n("post_voting.topic.activity"),
            disabled: topicController.filter === ORDER_BY_ACTIVITY_FILTER,
            className: `post-voting-answers-headers-sort-activity ${
              topicController.filter === ORDER_BY_ACTIVITY_FILTER
                ? "active"
                : ""
            }`,
          }),
        ]),
      ])
    );

    return result;
  });

  api.decorateWidget("post-avatar:after", function (helper) {
    const result = [];
    const model = helper.getModel();

    if (model.topic?.is_post_voting) {
      const postVotingPost = helper.attach("post-voting-post", {
        count: model.get("post_voting_vote_count"),
        post: model,
      });

      result.push(postVotingPost);
    }

    return result;
  });

  api.includePostAttributes(
    "comments",
    "comments_count",
    "post_voting_user_voted_direction",
    "post_voting_has_votes"
  );
}

function customizePostMenu(api, container) {
  const siteSettings = container.lookup("service:site-settings");

  const transformerRegistered = api.registerValueTransformer(
    "post-menu-buttons",
    ({ value: dag, context: { post, buttonKeys } }) => {
      if (post.post_voting_has_votes !== undefined) {
        dag.add("post-voting-answer", PostVotingAnswerButton, {
          after: [buttonKeys.SHOW_MORE, buttonKeys.REPLY],
        });

        dag.delete(buttonKeys.REPLY);

        if (
          post.post_number !== 1 &&
          !siteSettings.post_voting_enable_likes_on_answers
        ) {
          dag.delete(buttonKeys.LIKE);
        }
      }
    }
  );

  api.renderInOutlet(
    "post-menu__after",
    class extends Component {
      static shouldRender(args) {
        return (
          args.post.post_voting_has_votes !== undefined &&
          !args.post.reply_to_post_number &&
          !(args.state.filteredRepliesView && args.state.repliesShown)
        );
      }

      <template>
        <PostVotingComments
          @post={{@outletArgs.post}}
          @canCreatePost={{@outletArgs.state.canCreatePost}}
        />
      </template>
    }
  );

  const silencedKey =
    transformerRegistered && "discourse.post-menu-widget-overrides";

  withSilencedDeprecations(silencedKey, () => customizeWidgetPostMenu(api));
}

function customizeWidgetPostMenu(api) {
  api.removePostMenuButton("reply", (attrs) => {
    return attrs.post_voting_has_votes !== undefined;
  });

  api.removePostMenuButton("like", (_attrs, _state, siteSetting) => {
    return (
      _attrs.post_voting_has_votes !== undefined &&
      _attrs.post_number !== 1 &&
      !siteSetting.post_voting_enable_likes_on_answers
    );
  });

  api.addPostMenuButton("answer", (attrs) => {
    if (
      attrs.post_voting_has_votes === undefined ||
      attrs.post_number !== 1 ||
      !attrs.canCreatePost
    ) {
      return;
    }

    const args = {
      action: "replyToPost",
      title: "post_voting.topic.answer.help",
      icon: "reply",
      className: "reply create fade-out",
      position: "last",
    };

    if (!attrs.mobileView) {
      args.label = "post_voting.topic.answer.label";
    }

    return args;
  });

  api.decorateWidget("post-menu:after", (helper) => {
    const result = [];
    const attrs = helper.widget.attrs;

    if (
      attrs.post_voting_has_votes !== undefined &&
      !attrs.reply_to_post_number &&
      !helper.widget.state.filteredRepliesShown
    ) {
      const post = helper.getModel();

      result.push(
        helper.attach("post-voting-comments", {
          post,
          canCreatePost: attrs.canCreatePost,
        })
      );
    }

    return result;
  });
}

export default {
  name: "post-voting-edits",
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

    if (!siteSettings.post_voting_enabled) {
      return;
    }

    withPluginApi("1.13.0", (api) => {
      initPlugin(api, container);
    });
  },
};
