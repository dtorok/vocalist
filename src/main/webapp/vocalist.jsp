<%@ page import="com.google.appengine.api.users.User" %>
<%@ page import="com.google.appengine.api.users.UserService" %>
<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
<%
    UserService userService = UserServiceFactory.getUserService();
    User user = userService.getCurrentUser();
    if (user == null) {
        String loginUrl = userService.createLoginURL(request.getRequestURI());
        pageContext.setAttribute("loginUrl", loginUrl);
%><html><head><script>window.document.location = "${loginUrl}";</script></head></html>
<%  } else {%>
<html>
<head>
    <meta name="viewport" content="user-scalable=no, width=device-width"/>
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <link rel="stylesheet" type="text/css" href="stylesheets/iphone.css" media="screen"/>

    <script type="text/javascript" src="js/jquery-1.7.1.js"></script>
    <script type="text/javascript" src="js/jsonrpc.js"></script>

    <style>
        div.demo { display: none; }

        div.lists { display:none; }
        div.loading { display: block; }
        div.flashcard { display: none; }

        div.lists ul li { cursor: pointer; }

        div.flashcard ul li { padding: 10px 10px 10px 10px; }
        div.flashcard span { display: block; text-align: center; }
        div.flashcard span.expression { font-size: large; }
        div.flashcard span.answer input { width: 250px }
        div.flashcard span.solution { font-size: small; margin-top: 10px; font-weight: normal; }
        div.flashcard span.position { font-size: small; }
    </style>

    <script type="text/javascript">
        var rpc = new JsonRPC('/api/', error);

        var words;
        var index;

        var stat;

        function statInit()
        {
            stat = {'correct': 0, 'wrong': 0};
        }
        function statStr()
        {
            str = "";

            str += "Correct: " + stat.correct + "\n";
            str += "Wrong: " + stat.wrong + "\n";

            return str;
        }
        function statAdd(word, correct)
        {
            rpc.call('word_stat_add', [word.id, correct ? "1" : "0"]);

            if (correct)
                stat.correct ++;
            else
                stat.wrong ++;
        }

        function checkAnswer(answer)
        {
            var word = words[index];

            if (word.word.toLowerCase() == answer.toLowerCase())
            {
                statAdd(word, true);
                alert('Correct');
            }
            else
            {
                statAdd(word, false);
                alert('Wrong: ' + word.word);
            }

            var ret = showNextCard();
            if (!ret)
            {
                alert("Quiz ended, statistics:\n" + statStr());
                $('.flashcard').hide();
                $('.lists').show();
            }
        }
        function showCard()
        {
            var word = words[index];

            var definition = word.definition.split(';').shuffle().join('; ');

            $('.flashcard').show();
            $('.flashcard span.expression').html(definition);
            $('.flashcard span.solution').hide().html(word.word);
            $('.flashcard span.position').html((index + 1) + ' / ' + words.length);

            $('.flashcard span.answer input.answer').val('');
        }
        function showNextCard()
        {
            index ++;

            if (index >= words.length)
                return false;

            showCard();

            return true;
        }
        function startFlashCards(data)
        {
            statInit();
            words = data.words.shuffle();
            index = 0;

            showCard();
        }

        function loadFlashCards(list_id)
        {
            rpc.call('list_get', [list_id], function(res) {
                $('.loading').hide();
                startFlashCards(res);
            });
        }

        function showLists(lists)
        {
            var li;
            var i, list;

            for (i=0; i < lists.length; i++)
            {
                list = lists[i];
                li = $('<li />');
                li.attr('rel', list['id']);
                li.html(list['name']);

                li.bind('click', function(e) {
                    $('.lists').hide();
                    loadFlashCards($(this).attr('rel'));
                });

                $('ul#lists').append(li);
            }

            $('.lists').show();
        }

        function loadLists()
        {
            rpc.call('list_list', [], function(lists) {
                $('.loading').hide();
                showLists(lists);
            });
        }


        function error(e)
        {
            alert(e);
        }

        Array.prototype.shuffle = function() {
            var s = [];
            while (this.length) s.push(this.splice(Math.random() * this.length, 1)[0]);
            while (s.length) this.push(s.pop());
            return this;
        }

        $(function()
        {
            //$('div.lists li').bind('click', function()
            //	{
            //		$('.lists').hide();
            //
            //		loadFlashCards($(this).attr('ref'));
            //	});

            $('form.answer').bind('submit', function()
            {
                checkAnswer($(this).find('input.answer').val());
                return false;
            });

            loadLists();
        });
    </script>

</head>
<body>

<div class="lists">

    <h1>Vocabulary lists</h1>
    <ul id="lists">
    </ul>
</div>

<div class="flashcard">
    <ul>
        <li>
            <span class="expression"></span>
            <span class="answer"><form class="answer"><input class="answer" type="text" name="answer"></form></span>
            <span class="solution"></span>
            <span class="position"></span>
        </li>
    </ul>
</div>

<div class="loading">
    <ul>
        <li>
            Loading...
        </li>
    </ul>
</div>

<div class="demo">
    <div class="button">Back</div>
    <div class="button-bold">+</div>
    <h1>Matches</h1>
    <h2>Today</h2>
    <ul>
        <li class="arrow">Brasil : Spain<span class="right">Topgame</span></li>
        <li>Argentina : England</li>
        <li>Italy : Poland</li>
        <li class="arrow">Netherlands : Portugal</li>
        <li>Germany : France<span class="right">Topgame</span>
        </li>
        <li>USA : Mexico</li>
    </ul>
    <ul><a href="alma"><li>Almafa</li></a></ul>
    <p>....How sour sweet music is<br/>
        When time is broke, and no proportion kept.<br/>
        So is it in the music of men's lives:<br/>
</div>
</body>
</html>
<% } %>