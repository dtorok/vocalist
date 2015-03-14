package hu.danisoft.vocalist.models;

import java.util.List;

/**
 * Created with IntelliJ IDEA.
 * User: dtorok
 * Date: 2015.03.14.
 * Time: 23:46
 * To change this template use File | Settings | File Templates.
 */
public class Vocalist extends VocalistShort {
    private List<Word> words;

    public Vocalist(String guid, String title, List<Word> words) {
        super(guid, title);
        this.words = words;
    }
}
