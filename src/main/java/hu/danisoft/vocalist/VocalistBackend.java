package hu.danisoft.vocalist;

import com.evernote.auth.EvernoteAuth;
import com.evernote.auth.EvernoteService;
import com.evernote.clients.ClientFactory;
import com.evernote.clients.NoteStoreClient;
import com.evernote.edam.notestore.NoteFilter;
import com.evernote.edam.notestore.NoteList;
import com.evernote.edam.type.Note;
import com.evernote.edam.type.NoteSortOrder;
import com.evernote.edam.type.Notebook;
import hu.danisoft.vocalist.models.Word;
import hu.danisoft.vocalist.models.Vocalist;
import hu.danisoft.vocalist.models.VocalistShort;

import java.io.InputStream;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;
import java.util.Properties;


public class VocalistBackend {

    public List<VocalistShort> listVocalists() {
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

            List<VocalistShort> l = new LinkedList<>();

            for (Note note : notes) {
                l.add(new VocalistShort(note.getGuid(), note.getTitle()));
            }

            return l;
        } catch (Exception e) {
            return new LinkedList();
        }
    }

    public Vocalist getVocalist(String guid) {
        try {
            NoteStoreClient noteStore = evernoteNoteStore();
            Note note = noteStore.getNote(guid, true, false, false, false);

            String content = note.getContent();
            List<Word> words = parseNote(content);
            return new Vocalist(guid, note.getTitle(), words);
        } catch (Exception e) {
            return null;
        }
    }

    private List<Word> parseNote(String content) {
        List<String> lines = Arrays.asList(content.split("\n"));
        List<Word> words = parseLines(lines);

        return words;
    }

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

            return new Word(parts[0], parts[1]);
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

    private Properties getProperties() throws Exception {
        String filename = "config.properties";

//        InputStream inputStream = getServletContext().getResourceAsStream(filename);
        InputStream inputStream = this.getClass().getClassLoader().getResourceAsStream(filename);

        Properties props = new Properties();
        props.load(inputStream);

        return props;
    }

    private Notebook getNotebookByName(NoteStoreClient noteStore, String name) throws Exception {
        List<Notebook> notebooks = noteStore.listNotebooks();
        for (Notebook notebook : notebooks) {
            if (notebook.getName().equals(name))
                return notebook;
        }

        return null;
    }

}