package hu.danisoft.vocalist;

import com.evernote.auth.EvernoteAuth;
import com.evernote.auth.EvernoteService;
import com.evernote.clients.ClientFactory;

import com.evernote.edam.notestore.NoteFilter;
import com.evernote.edam.notestore.NoteList;
import com.evernote.edam.type.Note;
import com.evernote.edam.type.NoteSortOrder;
import com.evernote.edam.type.Notebook;
import com.google.appengine.api.users.User;
import com.google.appengine.api.users.UserService;
import com.google.appengine.api.users.UserServiceFactory;

import com.google.gson.Gson;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.util.*;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.evernote.clients.NoteStoreClient;

class WordList extends Object {
    int active;
    String id;
    String name;
    int wordcount;
}

class Words extends Object {
    String id;
    int active;
    List<Word> words;
}

class Word extends Object {
    int active;
    String id;
    String definition;
    String word;
    int failed;
    int succeeded;
}

class RPCRequest extends Object {
    String id;
    String method;
    List<String> params;
}

class RPCResponse extends Object {
    String id;
}
class RPCResponseLists extends RPCResponse {
    List<WordList> result;
}

class RPCResponseWords extends RPCResponse {
    Words result;
}


public class VocalistServlet extends HttpServlet {

    private Notebook getNotebookByName(NoteStoreClient noteStore, String name) throws Exception {
        List<Notebook> notebooks = noteStore.listNotebooks();
        for (Notebook notebook : notebooks) {
            if (notebook.getName().equals(name))
                return notebook;
        }

        return null;
    }

    private NoteStoreClient evernoteNoteStore() throws Exception {
        String token;
        EvernoteService serviceType;
        Boolean production = true;

        if (production) {
            token = getProperties().getProperty("evernote_token");
            serviceType = EvernoteService.PRODUCTION;
        } else {
            token = getProperties().getProperty("evernote_token_sandbox");
            serviceType = EvernoteService.SANDBOX;
        }
        EvernoteAuth evernoteAuth = new EvernoteAuth(serviceType, token);
        ClientFactory factory = new ClientFactory(evernoteAuth);
        NoteStoreClient noteStore = factory.createNoteStoreClient();

        return noteStore;
    }

	private String testNoteBooks() throws Exception {
        NoteStoreClient noteStore = evernoteNoteStore();

        String resp = "\n";

        List<Notebook> notebooks = noteStore.listNotebooks();
        for (Notebook notebook : notebooks) {
            resp = resp + "- " + notebook.getName() + "\n";
        }

        return resp;
	}

    private String testNotes() throws Exception {
        NoteStoreClient noteStore = evernoteNoteStore();

        String resp = "\n";

        String notebook_name = getProperties().getProperty("notebook_name");
        Notebook notebook = getNotebookByName(noteStore, notebook_name);
        if (notebook == null) {
            return "Notebook " + notebook_name + " not found...";
        }

        NoteFilter filter = new NoteFilter();
        filter.setNotebookGuid(notebook.getGuid());
        filter.setOrder(NoteSortOrder.UPDATED.getValue());
        filter.setAscending(false);

        NoteList noteList = noteStore.findNotes(filter, 0, 100);
        List<Note> notes = noteList.getNotes();

        for (Note note : notes) {
            resp = resp + "- " + note.getTitle() + "\n";
        }

        return resp;
    }

    private void testNoteParsing(PrintWriter writer) throws Exception {
        String guid = "9b9c6cc6-2930-4c48-a7e1-73a51a9c6b66";
        String content = evernoteGetContent(guid);
        List<String> lines = Arrays.asList(content.split("\n"));

        List<Word> words = new LinkedList<>();

        for (String line : lines) {
            writer.println("===================");
            writer.println("1 " + line);

            if (!(line.startsWith("<div>") && line.endsWith("</div>")))
                continue;

            writer.println("2 " + line);

            line = line.substring(5, line.length()-6);

            writer.println("3 " + line);

            int commentIndex = line.indexOf('#');
            writer.println("3.1 " + commentIndex);
            if (commentIndex >= 0) {
                line = line.substring(0, commentIndex);
            }

            writer.println("4 " + line);

            if (line.equals(""))
                continue;

            writer.println("5 " + line);
            writer.println("5.1 " + line.codePointAt(3));
            writer.println("5.2 " + line.codePointAt(17));

            String[] parts = line.split("[\u0020\u00A0][  ][  ][  ][  ]");

            writer.println("6 " + parts.length);

            Word w = new Word();
            w.active = 1;
            w.definition = parts[1];
            w.word = parts[0];
            w.failed = 0;
            w.succeeded = 0;
            w.id = "?";

            writer.println("7 " + w);

            words.add(w);
        }

        writer.println(words);


    }

    private void testEncoding(PrintWriter writer) {
        writer.println("éáűőúöüóí ÉÁŰŐÚÖÜÓÍ");
    }

    private void testConfig(HttpServletRequest req, PrintWriter writer) throws Exception {
        String filename = req.getParameter("filename");
        if (filename == null)
            filename = "config.properties";

//        InputStream inputStream = getServletContext().getResourceAsStream(filename);
        InputStream inputStream = this.getClass().getClassLoader().getResourceAsStream(filename);

        Properties props = new Properties();
        props.load(inputStream);

        writer.println(props.getProperty("notebook_name"));
    }

    private void test(User currentUser, HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("text/plain");
        resp.setCharacterEncoding("utf-8");

        PrintWriter writer = resp.getWriter();

        writer.println("Hello " + currentUser.getNickname() + ", this is the test server of vocalist!\n");

        try {
            testConfig(req, resp.getWriter());
            testEncoding(resp.getWriter());
            writer.println("## Note parsing");
            testNoteParsing(resp.getWriter());
            writer.println("## Notebooks");
            writer.println(testNoteBooks());
            writer.println("## Notes");
            writer.println(testNotes());
        } catch (Exception e) {
            e.printStackTrace(resp.getWriter());
        }

    }


	@Override
	public void doGet(HttpServletRequest req, HttpServletResponse resp) 
				throws IOException {
        UserService userService = UserServiceFactory.getUserService();
        User currentUser = userService.getCurrentUser();

        if (currentUser == null) {
            resp.sendRedirect(userService.createLoginURL(req.getRequestURI()));
            return;
        }

        test(currentUser, req, resp);
	}

    private List<WordList> evernoteGetWordLists() {
        try {
            NoteStoreClient noteStore = evernoteNoteStore();

            String notebook_name = getProperties().getProperty("notebook_name");
            Notebook notebook = getNotebookByName(noteStore, notebook_name);
            if (notebook == null) {
                return new LinkedList();
            }

            NoteFilter filter = new NoteFilter();
            filter.setNotebookGuid(notebook.getGuid());
            filter.setOrder(NoteSortOrder.UPDATED.getValue());
            filter.setAscending(false);

            NoteList noteList = noteStore.findNotes(filter, 0, 100);
            List<Note> notes = noteList.getNotes();

            List<WordList> l = new LinkedList<>();

            for (Note note : notes) {
                l.add(newWordList(note.getGuid(), note.getTitle()));
            }

            return l;
        } catch (Exception e) {
            return new LinkedList();
        }
    }

    private Properties getProperties() throws Exception {
        String filename = "config.properties";

//        InputStream inputStream = getServletContext().getResourceAsStream(filename);
        InputStream inputStream = this.getClass().getClassLoader().getResourceAsStream(filename);

        Properties props = new Properties();
        props.load(inputStream);

        return props;
    }

    private String evernoteGetContent(String guid) {
        try {
            NoteStoreClient noteStore = evernoteNoteStore();

            Note note = noteStore.getNote(guid, true, false, false, false);
            return note.getContent();
        } catch (Exception e) {
            return null;
        }
    }

//    private List<String> removeEmptyLines(List<String> lines) {
//        List<String> linesWithContent = new LinkedList<>();
//
//        for (String line : lines) {
//            if (!"".equals(line))
//                linesWithContent.add(line);
//        }
//
//        return linesWithContent;
//    }
//
//    private List<String> listItemsOnly(List<String> lines) {
//        List<String> listItems = new LinkedList<>();
//
//        for (String line : lines) {
//            if (line.startsWith("-"))
//                listItems.add(line);
//        }
//
//        return listItems;
//    }

    private Word parseLine(String line) {
        try {
//            if (!line.startsWith("- "))
//                return null;

            if (!(line.startsWith("<div>") && line.endsWith("</div>")))
                return null;

            line = line.substring(5, line.length()-6);

            int commentIndex = line.indexOf('#');
            if (commentIndex >= 0) {
                line = line.substring(0, commentIndex);
            }

            if (line.equals(""))
                return null;

            String[] parts = line.split("[\u0020\u00A0][  ][  ][  ][  ]");

            Word w = new Word();
            w.active = 1;
            w.definition = parts[1];
            w.word = parts[0];
            w.failed = 0;
            w.succeeded = 0;
            w.id = "?";

            return w;
        } catch (Exception e) {
            return null;
        }
    }

    private List<Word> parseLines(List<String> lines) {
        List<Word> words = new LinkedList<>();

        for (String line : lines) {
            Word word = parseLine(line);
            if (word != null)
                words.add(word);
        }

        return words;
    }

    private List<Word> contentToWordList(String content) {
        List<String> lines = Arrays.asList(content.split("\n"));
        List<Word> words = parseLines(lines);
//        lines = removeEmptyLines(lines);
//        lines = listItemsOnly(lines);

        return words;
    }

    private WordList newWordList(String id, String name) {
        WordList w = new WordList();
        w.id = id;
        w.name = name;
        w.active = 1;
        w.wordcount = 42;
        return w;
    }

    @Override
    public void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        resp.setContentType("application/json");
        resp.setCharacterEncoding("utf-8");

        UserService userService = UserServiceFactory.getUserService();
        User currentUser = userService.getCurrentUser();

        if (currentUser == null) {
            resp.sendRedirect(userService.createLoginURL(req.getRequestURI()));
            return;
        }

        BufferedReader reader = req.getReader();
        String line = reader.readLine();
        Gson gson = new Gson();
        RPCRequest call = gson.fromJson(line, RPCRequest.class);

        if ("list_list".equals(call.method)) {
            RPCResponseLists res = new RPCResponseLists();
            res.id = call.id;
            res.result = evernoteGetWordLists();
            resp.getWriter().println(gson.toJson(res));
        } else if ("list_get".equals(call.method)) {
            String guid = call.params.get(0);
            String content = evernoteGetContent(guid);
            List<Word> words = contentToWordList(content);

            RPCResponseWords res = new RPCResponseWords();
            res.id = call.id;
            res.result = new Words();
            res.result.id = guid;
            res.result.words = words;

            resp.getWriter().println(gson.toJson(res));
//            resp.getWriter().println("{\"id\":" + call.id + ",\"result\":{\"id\":\"10\",\"0\":\"10\",\"name\":\"Lession 2\",\"1\":\"Lession 2\",\"active\":\"1\",\"2\":\"1\",\"words\":[{\"id\":\"579\",\"list_id\":\"10\",\"word\":\"guess what\",\"definition\":\"k\\u00e9pzeld\",\"active\":\"1\",\"succeeded\":\"6\",\"failed\":\"0\"},{\"id\":\"580\",\"list_id\":\"10\",\"word\":\"standing ovation\",\"definition\":\"\\u00e1ll\\u00f3 ov\\u00e1ci\\u00f3\",\"active\":\"1\",\"succeeded\":\"5\",\"failed\":\"0\"},{\"id\":\"581\",\"list_id\":\"10\",\"word\":\"embarrassing\",\"definition\":\"k\\u00ednos\",\"active\":\"1\",\"succeeded\":\"2\",\"failed\":\"4\"},{\"id\":\"582\",\"list_id\":\"10\",\"word\":\"to treat sy well\",\"definition\":\"j\\u00f3l b\\u00e1nik valakivel\",\"active\":\"1\",\"succeeded\":\"4\",\"failed\":\"0\"},{\"id\":\"583\",\"list_id\":\"10\",\"word\":\"I know him from early days.\",\"definition\":\"R\\u00e9gebbr\\u0151l ismerem \\u0151t.\",\"active\":\"1\",\"succeeded\":\"6\",\"failed\":\"0\"},{\"id\":\"584\",\"list_id\":\"10\",\"word\":\"clause\",\"definition\":\"tagmondat\",\"active\":\"1\",\"succeeded\":\"5\",\"failed\":\"0\"},{\"id\":\"585\",\"list_id\":\"10\",\"word\":\"We bought the tickets in advance.\",\"definition\":\"El\\u0151re megvett\\u00fck a jegyeket.\",\"active\":\"1\",\"succeeded\":\"2\",\"failed\":\"3\"},{\"id\":\"586\",\"list_id\":\"10\",\"word\":\"Thank you in advance.\",\"definition\":\"El\\u0151re is k\\u00f6sz\\u00f6n\\u00f6m.\",\"active\":\"1\",\"succeeded\":\"3\",\"failed\":\"3\"},{\"id\":\"587\",\"list_id\":\"10\",\"word\":\"I have tons of tasks.\",\"definition\":\"Rengeteg feladatom van.\",\"active\":\"1\",\"succeeded\":\"4\",\"failed\":\"1\"},{\"id\":\"588\",\"list_id\":\"10\",\"word\":\"rehearsal\",\"definition\":\"zenei\\/sz\\u00ednh\\u00e1zi pr\\u00f3ba\",\"active\":\"1\",\"succeeded\":\"1\",\"failed\":\"3\"},{\"id\":\"589\",\"list_id\":\"10\",\"word\":\"reproach\",\"definition\":\"szemreh\\u00e1ny\\u00e1s\",\"active\":\"1\",\"succeeded\":\"3\",\"failed\":\"1\"},{\"id\":\"590\",\"list_id\":\"10\",\"word\":\"to approach sg\",\"definition\":\"megk\\u00f6zel\\u00edt valamit\",\"active\":\"1\",\"succeeded\":\"4\",\"failed\":\"2\"},{\"id\":\"591\",\"list_id\":\"10\",\"word\":\"particular\",\"definition\":\"konkr\\u00e9t\",\"active\":\"1\",\"succeeded\":\"6\",\"failed\":\"0\"},{\"id\":\"592\",\"list_id\":\"10\",\"word\":\"to concern sg\",\"definition\":\"vonatkozik vmire\",\"active\":\"1\",\"succeeded\":\"6\",\"failed\":\"0\"},{\"id\":\"593\",\"list_id\":\"10\",\"word\":\"disastrous\",\"definition\":\"katasztr\\u00f3f\\u00e1lis\",\"active\":\"1\",\"succeeded\":\"2\",\"failed\":\"2\"},{\"id\":\"594\",\"list_id\":\"10\",\"word\":\"terrific\",\"definition\":\"sz\\u00f6rnyen j\\u00f3\",\"active\":\"1\",\"succeeded\":\"4\",\"failed\":\"0\"},{\"id\":\"595\",\"list_id\":\"10\",\"word\":\"to oversee\",\"definition\":\"fel\\u00fcgyel, ir\\u00e1ny\\u00edt, menedzsel\",\"active\":\"1\",\"succeeded\":\"6\",\"failed\":\"0\"},{\"id\":\"596\",\"list_id\":\"10\",\"word\":\"quite frankly\",\"definition\":\"eg\\u00e9szen \\u0151szint\\u00e9n\",\"active\":\"1\",\"succeeded\":\"5\",\"failed\":\"0\"},{\"id\":\"597\",\"list_id\":\"10\",\"word\":\"You spilled the coffee all over me.\",\"definition\":\"R\\u00e1m l\\u00f6ttyentetted az eg\\u00e9sz k\\u00e1v\\u00e9t.\",\"active\":\"1\",\"succeeded\":\"5\",\"failed\":\"0\"},{\"id\":\"598\",\"list_id\":\"10\",\"word\":\"exhausted\",\"definition\":\"kimer\\u00fclt\",\"active\":\"1\",\"succeeded\":\"6\",\"failed\":\"0\"},{\"id\":\"599\",\"list_id\":\"10\",\"word\":\"to be used to sg\",\"definition\":\"hozz\\u00e1szokott valamihez\",\"active\":\"1\",\"succeeded\":\"5\",\"failed\":\"1\"},{\"id\":\"600\",\"list_id\":\"10\",\"word\":\"The holiday in question\",\"definition\":\"a k\\u00e9rd\\u00e9ses nyaral\\u00e1s\",\"active\":\"1\",\"succeeded\":\"2\",\"failed\":\"2\"},{\"id\":\"601\",\"list_id\":\"10\",\"word\":\"as requested\",\"definition\":\"ahogyan k\\u00e9rt\\u00e9k (k\\u00e9rve volt :)\",\"active\":\"1\",\"succeeded\":\"6\",\"failed\":\"0\"},{\"id\":\"602\",\"list_id\":\"10\",\"word\":\"We came here in order to buy this.\",\"definition\":\"Az\\u00e9rt j\\u00f6tt\\u00fcnk, hogy megvegy\\u00fck ezt.\",\"active\":\"1\",\"succeeded\":\"4\",\"failed\":\"1\"},{\"id\":\"603\",\"list_id\":\"10\",\"word\":\"in a most impolite way\",\"definition\":\"kifejezetten udvariatlanul\",\"active\":\"1\",\"succeeded\":\"3\",\"failed\":\"3\"},{\"id\":\"604\",\"list_id\":\"10\",\"word\":\"we were offered no explanation\",\"definition\":\"nem kaptunk semmilyen magyar\\u00e1zatot\",\"active\":\"1\",\"succeeded\":\"3\",\"failed\":\"1\"},{\"id\":\"605\",\"list_id\":\"10\",\"word\":\"on arrival\",\"definition\":\"meg\\u00e9rkez\\u00e9skor\",\"active\":\"1\",\"succeeded\":\"4\",\"failed\":\"1\"},{\"id\":\"606\",\"list_id\":\"10\",\"word\":\"we arrived at the hotel\",\"definition\":\"meg\\u00e9rkezt\\u00fcnk a hotelhez\",\"active\":\"1\",\"succeeded\":\"3\",\"failed\":\"1\"},{\"id\":\"607\",\"list_id\":\"10\",\"word\":\"to be not up to the standard\",\"definition\":\"nem \\u00fcti meg a l\\u00e9cet\",\"active\":\"1\",\"succeeded\":\"3\",\"failed\":\"1\"},{\"id\":\"608\",\"list_id\":\"10\",\"word\":\"disorganization\",\"definition\":\"fejetlens\\u00e9g, rendezetlens\\u00e9g\",\"active\":\"1\",\"succeeded\":\"3\",\"failed\":\"1\"},{\"id\":\"609\",\"list_id\":\"10\",\"word\":\"some form of\",\"definition\":\"valami f\\u00e9le\",\"active\":\"1\",\"succeeded\":\"2\",\"failed\":\"4\"},{\"id\":\"610\",\"list_id\":\"10\",\"word\":\"I look forward to hearing from you.\",\"definition\":\"V\\u00e1rom v\\u00e1lasz\\u00e1t.\",\"active\":\"1\",\"succeeded\":\"3\",\"failed\":\"3\"}]},\"error\":null}");
        } else if ("word_stat_add".equals(call.method)) {
            // disabled => dummy answer
            resp.getWriter().println("{\"id\":" + call.id + ",\"result\":true,\"error\":null}");
        } else {
            resp.getWriter().println(call.method);
            resp.getWriter().println(call.params);
        }
    }
}