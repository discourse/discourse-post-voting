import { hbs } from "ember-cli-htmlbars";
import { registerWidgetShim } from "discourse/widgets/render-glimmer";

registerWidgetShim(
  "post-voting-comments",
  "div.post-voting-comments-shim",
  hbs`<PostVotingComments
    @post={{@data.post}}
    @canCreatePost={{@data.canCreatePost}}
  />`
);
