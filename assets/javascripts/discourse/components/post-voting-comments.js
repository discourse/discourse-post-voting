import { action } from "@ember/object";
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";

export default class PostVotingComments extends Component {
  @tracked comments = this.args.post.comments;

  get moreCommentCount() {
    return this.args.post.comments_count - this.comments.length;
  }

  get lastCommentId() {
    return this.comments?.[this.comments.length - 1]?.id ?? 0;
  }

  @action
  appendComments(comments) {
    this.comments.pushObjects(comments);
  }

  @action
  removeComment(commentId) {
    const indexToRemove = this.comments.findIndex(
      (comment) => comment.id === commentId
    );

    if (indexToRemove !== -1) {
      const comment = { ...this.comments[indexToRemove], deleted: true };

      this.comments.replace(indexToRemove, 1, [comment]);
      this.args.post.comments_count--;
    }
  }

  @action
  updateComment(comment) {
    const index = this.comments.findIndex(
      (oldComment) => oldComment.id === comment.id
    );
    this.comments.replace(index, 1, [comment]);
  }

  @action
  vote(commentId) {
    const index = this.comments.findIndex(
      (oldComment) => oldComment.id === commentId
    );
    const comment = this.comments[index];

    const updatedComment = {
      ...comment,
      post_voting_vote_count: comment.post_voting_vote_count + 1,
      user_voted: true,
    };
    this.comments.replace(index, 1, [updatedComment]);
  }

  @action
  removeVote(commentId) {
    const index = this.comments.findIndex(
      (oldComment) => oldComment.id === commentId
    );
    const comment = this.comments[index];

    const updatedComment = {
      ...comment,
      post_voting_vote_count: comment.post_voting_vote_count - 1,
      user_voted: false,
    };
    this.comments.replace(index, 1, [updatedComment]);
  }
}
