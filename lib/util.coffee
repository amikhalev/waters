module.exports =
  sequential: (promises) ->
    new Promise (resolve, reject) ->
      results = []
      iter = ->
        return resolve results if results.length is promises.length
        promises[results.length]()
        .then (a) ->
          results.push a
          iter()
        , reject
      iter()
