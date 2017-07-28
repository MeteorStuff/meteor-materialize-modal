Package.describe({
  name: "meteorstuff:materialize-modal",
  summary: "Display a modal via Materialize written in coffeescript",
  version: "1.1.3",
  git: "https://github.com/MeteorStuff/meteor-materialize-modal.git"
});

Package.onUse(function(api, where) {
  api.versionsFrom("METEOR@1.4");

  api.use([
    'underscore',
    'templating',
    'blaze',
    'jquery',
    'reactive-var'
  ], 'client');

  api.use([
    'softwarerero:accounts-t9n@1.3.8',
    'coffeescript'
  ], ["client"]);

  api.addFiles([
    'lib/modal.css',
    'lib/modal.html',
    'lib/MaterializeModal.coffee',
    'lib/modal.coffee',
    'lib/t9n.coffee'
  ], 'client');

  if (api.export) {
    api.export('MaterializeModal')
  }

});


Package.onTest(function(api) {
  api.use("meteorstuff:materialize-modal", 'client');
  api.use(['tinytest', 'test-helpers', 'coffeescript'], 'client');
  api.add_files('tests/modal_tests.coffee', 'client');
});
