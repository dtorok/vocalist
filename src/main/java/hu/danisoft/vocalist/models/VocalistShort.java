package hu.danisoft.vocalist.models;


public class VocalistShort {
    private String guid;
    private String title;

    public VocalistShort(String guid, String title) {
        setGuid(guid);
        setTitle(title);
    }

    public String getGuid() {
        return guid;
    }

    public void setGuid(String guid) {
        this.guid = guid;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }
}
