robotParser = require('../lib/parse-robot')
libdocParser = require('../lib/parse-libdoc')
fs = require 'fs'
PACKAGE_NAME = 'autocomplete-robot-framework'
CFG_KEY = 'autocomplete-robot-framework'

# Credits - https://raw.githubusercontent.com/atom/autocomplete-atom-api/master/spec/provider-spec.coffee
getCompletions = (editor, provider)->
  cursor = editor.getLastCursor()
  start = cursor.getBeginningOfCurrentWordBufferPosition()
  end = cursor.getBufferPosition()
  prefix = editor.getTextInRange([start, end])
  request =
    editor: editor
    bufferPosition: end
    scopeDescriptor: cursor.getScopeDescriptor()
    prefix: prefix
  provider.getSuggestions(request)

describe 'Robot Framework keywords autocompletions', ->
  [editor, provider] = []
  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage(PACKAGE_NAME)
    runs ->
      provider = atom.packages.getActivePackage(PACKAGE_NAME).mainModule.getProvider()
    waitsForPromise -> atom.workspace.open('autocomplete/test_autocomplete_keywords.robot')
    waitsFor ->
      return !provider.loading
    , 'Provider should finish loading', 500
    runs ->
      editor = atom.workspace.getActiveTextEditor()

  describe 'Autocomplete', ->
    it 'suggest standard keywords', ->
      editor.setCursorBufferPosition([Infinity, Infinity])
      editor.insertText(' callm')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0].displayText).toEqual('Call Method')
    it 'suggest keywords in current editor', ->
      editor.setCursorBufferPosition([Infinity, Infinity])
      editor.insertText(' runprog')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Run Program')
    it 'suggest all keywords from that file when prefix is identical with file name', ->
      editor.setCursorBufferPosition([Infinity, Infinity])
      editor.insertText(' fileprefix')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(3)
          expect(suggestions[0]?.displayText).toEqual('FilePrefix')
          expect(suggestions[1]?.displayText).toEqual('File keyword 1')
          expect(suggestions[2]?.displayText).toEqual('File keyword 2')
    it 'show documentation in suggestions', ->
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' withdoc')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(3)
          expect(suggestions[0]?.displayText).toEqual('With documentation')
          expect(suggestions[0]?.description).toEqual('documentation. Arguments: arg1, arg2, arg3')
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' withdoc2')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('With documentation 2')
          expect(suggestions[0]?.description).toEqual('documentation. Arguments: arg1, arg2, arg3')
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' withoutdoc')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toBeGreaterThan(0)
          expect(suggestions[0]?.displayText).toEqual('Without documentation')
          expect(suggestions[0]?.description).toEqual(' Arguments: arg1, arg2, arg3')
    it 'show arguments in suggestions', ->
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' witharg')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toBeGreaterThan(0)
          expect(suggestions[0]?.displayText).toEqual('With arguments')
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' withoutarg')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toBeGreaterThan(0)
          expect(suggestions[0]?.displayText).toEqual('Without arguments')
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' withdefarg')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toBeGreaterThan(0)
          expect(suggestions[0]?.displayText).toEqual('With default value arguments')
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' withemb')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toBeGreaterThan(0)
          expect(suggestions[0]?.displayText).toEqual('With embedded ${arg1} arguments ${arg2}')
    it 'accept prefix containing dot', ->
      runs ->
        atom.config.set("#{CFG_KEY}.externalLibrary.HttpLibraryHTTP", true)
      waitsFor ->
        return !provider.loading
      , 'Provider should finish loading', 500
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' HttpLibrary.HTTPd')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toBeGreaterThan(0)
          expect(suggestions[0]?.displayText).toEqual('DELETE')
    it 'show suggestions from current editor first', ->
      editor.setCursorBufferPosition([Infinity, Infinity])
      editor.insertText(' run')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toBeGreaterThan(2)
          expect(suggestions[0]?.displayText).toEqual('Run Program')
    it 'do not show keywords private to other files', ->
      editor.setCursorBufferPosition([Infinity, Infinity])
      editor.insertText(' privatek')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(0)
    it 'show keywords visible onlyinside current file', ->
      waitsForPromise -> atom.workspace.open('autocomplete/test_autocomplete_testcase.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' privatek')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Private keyword')
    it 'matches beginning of word', ->
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' dp')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toBeGreaterThan(1)
          expect(suggestions[0]?.displayText).toEqual('Dot.punctuation keyword')
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' dot')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toBeGreaterThan(1)
          expect(suggestions[0]?.displayText).toEqual('Dot.punctuation keyword')
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' punct')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Dot.punctuation keyword')
    it 'supports mixed case', ->
      waitsForPromise -> atom.workspace.open('autocomplete/test_autocomplete_testcase.robot')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' callme')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Call Method')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' CALLME')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Call Method')
    it 'supports dot notation', ->
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' builtin.callme')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Call Method')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' builtincallme')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Call Method')
    it 'supports dot notation with mixed case', ->
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' BUILTIN.CALLME')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Call Method')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' BUILTINCALLME')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Call Method')

  describe 'Autocomplete configuration', ->
    it 'react on showArguments configuration changes', ->
      runs ->
        atom.config.set("#{CFG_KEY}.showArguments", true)
      waitsFor ->
        return !provider.loading
      , 'Provider should finish loading', 500
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' runprog')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Run Program - args')
      runs ->
        atom.config.set("#{CFG_KEY}.showArguments", false)
      waitsFor ->
        return !provider.loading
      , 'Provider should finish loading', 500
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' runprog')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Run Program')
    it 'react on excludeDirectories configuration changes', ->
      runs ->
        atom.config.set("#{CFG_KEY}.excludeDirectories", [])
      waitsFor ->
        return !provider.loading
      , 'Provider should finish loading', 500
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' runprog')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(1)
            expect(suggestions[0]?.displayText).toEqual('Run Program')
      runs ->
        atom.config.set("#{CFG_KEY}.excludeDirectories", ['autocomplete'])
      waitsFor ->
        return !provider.loading
      , 'Provider should finish loading', 500
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' runprog')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(0)
    it 'react on standardLibrary configuration changes', ->
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' callm')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(1)
            expect(suggestions[0].displayText).toEqual('Call Method')
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' built')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(1)
            expect(suggestions[0].displayText).toEqual('BuiltIn')
      runs ->
        atom.config.set("#{CFG_KEY}.standardLibrary.BuiltIn", false)
      waitsFor ->
        return !provider.loading
      , 'Provider should finish loading', 500
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' callm')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(0)
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' built')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(0)
    it 'react on externalLibrary configuration changes', ->
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' dowfi')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(0)
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' ftp')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toBeGreaterThan(0)
            expect(suggestions[0].displayText).not.toEqual('FtpLibrary')
      runs ->
        atom.config.set("#{CFG_KEY}.externalLibrary.FtpLibrary", true)
      waitsFor ->
        return !provider.loading
      , 'Provider should finish loading', 500
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' dowfi')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(1)
            expect(suggestions[0].displayText).toEqual('Download File')
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' ftpli')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(1)
            expect(suggestions[0].displayText).toEqual('FtpLibrary')
    it 'react on processLibdocFiles configuration changes', ->
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' autocompletelibdoc')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(1)
            expect(suggestions[0].displayText).toEqual('Autocomplete libdoc test')
      runs ->
        atom.config.set("#{CFG_KEY}.processLibdocFiles", false)
      waitsFor ->
        return !provider.loading
      , 'Provider should finish loading', 500
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' autocompletelibdoc')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(0)
    it 'react on maxFileSize configuration changes', ->
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' limitfilesize')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(1)
            expect(suggestions[0].displayText).toEqual('Limit File Size')
      runs ->
        atom.config.set("#{CFG_KEY}.maxFileSize", 39)
      waitsFor ->
        return !provider.loading
      , 'Provider should finish loading', 500
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' limitfilesize')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(0)
    it 'react on showLibrarySuggestions configuration changes', ->
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' built')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(1)
            expect(suggestions[0].displayText).toEqual('BuiltIn')
      runs ->
        atom.config.set("#{CFG_KEY}.showLibrarySuggestions", false)
      waitsFor ->
        return !provider.loading
      , 'Provider should finish loading', 500
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' built')
        waitsForPromise ->
          getCompletions(editor, provider).then (suggestions) ->
            expect(suggestions.length).toEqual(0)
    it 'react on avoidDotNotation configuration changes', ->
      runs ->
        atom.config.set("#{CFG_KEY}.avoidDotNotation", true)
      waitsFor ->
        return !provider.loading
      , 'Provider should finish loading', 500
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' builtin.callme')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Call Method')
          expect(suggestions[0]?.replacementPrefix).toEqual('builtin.callme')
      runs ->
        atom.config.set("#{CFG_KEY}.avoidDotNotation", false)
      waitsFor ->
        return !provider.loading
      , 'Provider should finish loading', 500
      runs ->
        editor.setCursorBufferPosition([Infinity, Infinity])
        editor.insertText(' builtin.callme')
      waitsForPromise ->
        getCompletions(editor, provider).then (suggestions) ->
          expect(suggestions.length).toEqual(1)
          expect(suggestions[0]?.displayText).toEqual('Call Method')
          expect(suggestions[0]?.replacementPrefix).toEqual('callme')

describe "Robot file detection", ->
  it 'should detect correct robot files', ->
    fixturePath = "#{__dirname}/../fixtures/autocomplete/detectRobot"

    content = fs.readFileSync("#{fixturePath}/detect-ok1.robot").toString()
    isRobot = robotParser.isRobot(content)
    expect(isRobot).toBe(true);

    content = fs.readFileSync("#{fixturePath}/detect-ok2.robot").toString()
    isRobot = robotParser.isRobot(content)
    expect(isRobot).toBe(true);

    content = fs.readFileSync("#{fixturePath}/detect-ok3.robot").toString()
    isRobot = robotParser.isRobot(content)
    expect(isRobot).toBe(true);

    content = fs.readFileSync("#{fixturePath}/detect-ok4.robot").toString()
    isRobot = robotParser.isRobot(content)
    expect(isRobot).toBe(true);

    content = fs.readFileSync("#{fixturePath}/detect-ok5.robot").toString()
    isRobot = robotParser.isRobot(content)
    expect(isRobot).toBe(true);

    content = fs.readFileSync("#{fixturePath}/detect-ok6.robot").toString()
    isRobot = robotParser.isRobot(content)
    expect(isRobot).toBe(true);

    content = fs.readFileSync("#{fixturePath}/detect-ok7.robot").toString()
    isRobot = robotParser.isRobot(content)
    expect(isRobot).toBe(true);

  it 'should detect incorrect robot files', ->
    fixturePath = "#{__dirname}/../fixtures/autocomplete/detectRobot"

    content = fs.readFileSync("#{fixturePath}/detect-wrong1.robot").toString()
    isRobot = robotParser.isRobot(content)
    expect(isRobot).toBe(false);

    content = fs.readFileSync("#{fixturePath}/detect-wrong2.robot").toString()
    isRobot = robotParser.isRobot(content)
    expect(isRobot).toBe(false);

    content = fs.readFileSync("#{fixturePath}/detect-wrong3.robot").toString()
    isRobot = robotParser.isRobot(content)
    expect(isRobot).toBe(false);

    content = fs.readFileSync("#{fixturePath}/detect-wrong4.robot").toString()
    isRobot = robotParser.isRobot(content)
    expect(isRobot).toBe(false);

    content = fs.readFileSync("#{fixturePath}/detect-wrong5.robot").toString()
    isRobot = robotParser.isRobot(content)
    expect(isRobot).toBe(false);

describe "Libdoc xml file detection", ->
  it 'should detect correct libdoc xml files', ->
    fixturePath = "#{__dirname}/../fixtures/autocomplete/detectLibdocXml"

    content = fs.readFileSync("#{fixturePath}/libdoc-ok.xml").toString()
    isLibdoc = libdocParser.isLibdoc(content)
    expect(isLibdoc).toBe(true);
  it 'should detect incorrect libdoc xml files', ->
    fixturePath = "#{__dirname}/../fixtures/autocomplete/detectLibdocXml"

    content = fs.readFileSync("#{fixturePath}/libdoc-wrong.xml").toString()
    isLibdoc = libdocParser.isLibdoc(content)
    expect(isLibdoc).toBe(false);
