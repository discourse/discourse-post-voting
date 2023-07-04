import { action } from "@ember/object";
import Component from "@glimmer/component";

export default class PostVotingButton extends Component {
  get buttonClasses() {
    let classes =
      this.args.direction === "up"
        ? "post-voting-button-upvote"
        : "post-voting-button-downvote";

    if (this.args.voted) {
      classes += " post-voting-button-voted";
    }

    return classes;
  }

  get iconName() {
    return this.args.direction === "up" ? "caret-up" : "caret-down";
  }

  @action
  onClick() {
    if (this.args.loading) {
      return false;
    }

    if (this.args.voted) {
      this.args.removeVote(this.args.direction);
    } else {
      this.args.vote(this.args.direction);
    }
  }
}
