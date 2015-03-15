package hu.danisoft.vocalist;

//import com.google.appengine.api.users.User;
//import com.google.appengine.api.users.UserService;
//import com.google.appengine.api.users.UserServiceFactory;
import com.google.gson.Gson;
import hu.danisoft.vocalist.models.Vocalist;
import hu.danisoft.vocalist.models.VocalistShort;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;


public class VocalistApi extends HttpServlet {

    private VocalistBackend backend = new VocalistBackend();

    @Override
    public void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("utf-8");
        resp.setHeader("Access-Control-Allow-Origin", "*");

//        UserService userService = UserServiceFactory.getUserService();
//        User currentUser = userService.getCurrentUser();
//
//        if (currentUser == null) {
//            resp.sendRedirect(userService.createLoginURL(req.getRequestURI()));
//            return;
//        }

        String path = req.getPathInfo();

        if (path == null) {
            resp.sendRedirect(req.getRequestURL().toString() + "/");
        } else if ("/".equals(path)) {
            vocalists(req, resp);
        } else if (path.length() > 1) {
            String guid = path;

            // trim starting /
            guid = guid.substring(1);

            // trim trailing /
            if (guid.charAt(guid.length() - 1) == '/') {
                guid = guid.substring(0, guid.length()-1);
            }

            vocalist(guid, req, resp);

        }
    }

    private void vocalists(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Gson gson = new Gson();

        List<VocalistShort> vocalists = backend.listVocalists();
        resp.getWriter().println(gson.toJson(vocalists));
    }

    private void vocalist(String guid, HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Gson gson = new Gson();
        Vocalist vocalist = backend.getVocalist(guid);

        resp.getWriter().println(gson.toJson(vocalist));
    }
}
