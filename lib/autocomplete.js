var keywordsRepo = require('./keywords');
var pathUtils = require('path')
var util = require('util');


var getSuggestions = function(prefix, currentResourceKey, settings) {
  prefix = prefix || '';
  settings = settings || {};


  var suggestions = [];
  var dotNotation = false;
  if(!dotNotation){
    var libraryNameSuggestions = getLibraryNameSuggestions(prefix, settings);
    Array.prototype.push.apply(suggestions, libraryNameSuggestions);
  }

  var keywordSuggestions = getKeywordSuggestions(prefix, currentResourceKey, dotNotation, settings);
  Array.prototype.push.apply(suggestions, keywordSuggestions);

  return suggestions;
}

// Suggests library names (ie. 'built' suggests 'BuiltIn')
var getLibraryNameSuggestions = function(prefix, settings){
  var suggestions = [];
  prefix = prefix.trim().toLowerCase();

  var keywordsMap = keywordsRepo.keywordsMap;
  var libraryNameSuggestions = [];
  for ( var resourceKey in keywordsMap) {
    var resource = keywordsMap[resourceKey];
    if (resource) {
      if(settings.showLibrarySuggestions){
        var resourceName = pathUtils.basename(resourceKey, ext);
        var libraryNameMatch = (resource.name.toLowerCase().indexOf(prefix) === 0);
        if(libraryNameMatch){
          libraryNameSuggestions.push({
            text : resource.name,
            displayText : resource.name,
            type : 'import',
            replacementPrefix : prefix
          });
        }
      }
    }
  }

  libraryNameSuggestions.sort(function(a, b) {
    return compareString(a.displayText, b.displayText)
  });

  return libraryNameSuggestions;
}

// Limit suggestions to a certain library if required.
// A prefix of 'builtin' should suggest all keywords within 'BuiltIn' library.
// 'builtinrun' should suggest all keywords matching 'run' within 'BuiltIn' library.
// This is enforced by 'resourceFilter' which will limit our search to only a certain library
// and 'keywordPrefix' which will contain only the keyword part of the prefix
// (for 'builtinrun' prefix, keywordPrefix will be 'run')
var getDotNotationInfo = function(prefix, settings){
  prefix = prefix.trim().toLowerCase();
  var keywordsMap = keywordsRepo.keywordsMap;
  if(settings.matchFileName){
    for ( var resourceKey in keywordsMap) {
      var resource = keywordsMap[resourceKey];
      if (resource) {
        var dotNotation = false;
        if(prefix.startsWith(resource.name.toLowerCase()+'.')){
          return {
            dotNotation : true,
            keywordPrefix : prefix.substring(resource.name.length+1, prefix.length),
            resourceFilter : resourceKey
          };
        }
        if(prefix.startsWith(resource.name.toLowerCase())){
          return {
            dotNotation : true,
            keywordPrefix : prefix.substring(resource.name.length, prefix.length),
            resourceFilter : resourceKey
          };
        }
      }
    }
  }
  return {
    dotNotation : false,
    keywordPrefix : prefix,
    resourceFilter : undefined
  };
}

var getKeywordSuggestions = function(prefix, currentResourceKey, dotNotation, settings) {
  currentResourceKey = pathUtils.normalize(currentResourceKey);
  currentResourceName = pathUtils.basename(currentResourceKey, pathUtils.extname(currentResourceKey));

  var dotNotationInfo = getDotNotationInfo(prefix, settings);

  // Get suggestion
  var scoredKeywords = keywordsRepo.score(dotNotationInfo.keywordPrefix, dotNotationInfo.resourceFilter);

  // Sort suggested keywords by score. If score is identical sort them alphabetically.
  scoredKeywords.sort(function(a, b) {
    var resourceNameA = pathUtils.basename(a.keyword.resource.resourceKey, pathUtils.extname(a.keyword.resource.resourceKey));
    var resourceNameB = pathUtils.basename(b.keyword.resource.resourceKey, pathUtils.extname(b.keyword.resource.resourceKey));

    if(resourceNameA===currentResourceName && resourceNameB!==currentResourceName){
      return -1;
    } else if(resourceNameB===currentResourceName && resourceNameA!==currentResourceName){
      return 1;
    } else if(a.score===b.score){
      return compareString(a.keyword.name, b.keyword.name)
    } else{
      return b.score - a.score;
    }
  });

  // Remove local (non visible) suggestions
  // Keywords within robot files containing test cases are not visible outside.
  var visibleKeywords = [];
  scoredKeywords.forEach(function(scoredKeyword){
    var keyword = scoredKeyword.keyword;
    var loadLocalKeywords = (currentResourceKey === keyword.resource.resourceKey); // Indicates whether we are looking for keywords in current ressource
    var isVisibleKeyword = true;
    if(keyword.local && !loadLocalKeywords){
      isVisibleKeyword = false;
    }
    if(isVisibleKeyword){
      visibleKeywords.push(keyword);
    }
  })

  // Convert to common suggestions format
  var keywordSuggestions = [];
  for(var i = 0; i < visibleKeywords.length; i++){
    var keyword = visibleKeywords[i];
    resourceKey = keyword.resource.resourceKey;
    keywordSuggestions.push({
      name: keyword.name,
      local: keyword.local,
      snippet : buildText(keyword),
      displayText : buildDisplayText(keyword, settings),
      type : 'keyword',
      leftLabel : buildLeftLabel(keyword),
      rightLabel : buildRightLabel(keyword, resourceKey, keyword.resource.name),
      description : buildDescription(keyword),
      replacementPrefix : dotNotation?'':prefix,
      resourceKey : resourceKey,
      keyword : keyword,
    })
  }

  if(keywordSuggestions.length > settings.maxKeywordsSuggestionsCap){
    keywordSuggestions.length = settings.maxKeywordsSuggestionsCap;
  }
  return keywordSuggestions;
}

var buildText = function(keyword) {
  var i;
  var argumentsStr = '';
  for (i = 0; i < keyword.arguments.length; i++) {
    var argument = keyword.arguments[i];
    argumentsStr += util.format('    ${%d:%s}', i + 1, argument);
  }

  return keyword.name + argumentsStr;
};

var buildDisplayText = function(keyword, settings) {
  if (settings.showArguments) {
    var argumentsStr = buildArgumentsString(keyword);
    if (argumentsStr){
      return util.format('%s - %s', keyword.name, argumentsStr);
    } else{
      return keyword.name;
    }
  } else {
    return keyword.name;
  }
};

var buildLeftLabel = function(keyword) {
  return '';
};
var buildRightLabel = function(keyword, path, fileName) {
  return fileName;
};
var buildDescription = function(keyword) {
  var argumentsStr = buildArgumentsString(keyword);
  var firstLine = keyword.documentation.split('\n')[0].trim();
  firstLine = firstLine.length===0 || firstLine.endsWith('.')?firstLine:firstLine+'.';
  return util.format('%s Arguments: %s', firstLine, argumentsStr);
};

var buildArgumentsString = function(keyword){
  var i;
  var argumentsStr = '';
  for (i = 0; i < keyword.arguments.length; i++) {
    var argument = keyword.arguments[i];
    argumentsStr += util.format('%s%s', i == 0 ? '' : ', ', argument);
  }
  return argumentsStr;
}

//http://stackoverflow.com/questions/1179366/is-there-a-javascript-strcmp
var compareString = function(str1, str2){
  return ( ( str1 == str2 ) ? 0 : ( ( str1 > str2 ) ? 1 : -1 ) );
}


module.exports = {
  getSuggestions : getSuggestions,
}
