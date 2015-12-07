package org.dbcli;

import jline.Terminal;
import jline.console.ConsoleReader;
import jline.console.completer.Completer;
import jline.console.history.History;
import jline.internal.Configuration;
import jline.internal.NonBlockingInputStream;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.lang.reflect.Field;
import java.util.Iterator;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

public class Console extends ConsoleReader {
    public static PrintWriter writer;
    //public static NonBlockingInputStream in;
    public static WindowsInputReader in;
    public static Terminal terminal;
    public static String charset;
    protected static ScheduledExecutorService threadPool = Executors.newScheduledThreadPool(5);
    private History his;
    private ScheduledFuture task;
    private EventReader monitor = new EventReader();
    private ActionListener event;
    private char[] keys;
    private boolean isBlocking = false;

    public Console() throws Exception {
        super();
        his = getHistory();
        setExpandEvents(false);
        setHandleUserInterrupt(true);
        setBellEnabled(false);
        in = new WindowsInputReader();
        ((NonBlockingInputStream) this.getInput()).shutdown();
        Field field = ConsoleReader.class.getDeclaredField("in");
        field.setAccessible(true);
        field.set(this, in);
        field.setAccessible(false);
        field = ConsoleReader.class.getDeclaredField("reader");
        field.setAccessible(true);
        charset = this.getTerminal().getOutputEncoding() == null ? Configuration.getEncoding() : this.getTerminal().getOutputEncoding();
        field.set(this, new InputStreamReader(in, charset));
        field.setAccessible(false);
        //in=(NonBlockingInputStream)this.getInput();
        Iterator<Completer> iterator = getCompleters().iterator();
        while (iterator.hasNext()) removeCompleter(iterator.next());
    }

    public String readLine(String prompt) throws IOException {
        isBlocking = false;
        if (isRunning()) setEvents(null, null);
        synchronized (in) {
            return super.readLine(prompt);
        }
    }


    public String readLine() throws IOException {
        return readLine((String) null);
    }

    public Boolean isRunning() {
        return this.task != null;
    }


    public synchronized void setEvents(ActionListener event, char[] keys) {
        this.event = event;
        this.keys = keys;
        this.isBlocking = false;
        if (this.task != null) {
            this.task.cancel(true);
            this.task = null;

        }
        if (this.event != null && this.keys != null) {
            this.monitor.counter = 0;
            //this.task=this.threadPool.schedule(this.monitor,1000,TimeUnit.MILLISECONDS);
            this.task = this.threadPool.scheduleWithFixedDelay(this.monitor, 1000, 200, TimeUnit.MILLISECONDS);
        }
    }

    public void setMultiplePrompt(String Content) {
        if (Content == null) {
            try {
                setHistoryEnabled(false);
                his.removeLast();
            } catch (Exception e) {
            }
        } else {
            setHistoryEnabled(true);
            if (!Content.equals("")) this.his.add(Content);
            this.his.moveToEnd();
        }
    }

    class EventReader implements Runnable {
        public int counter = 0;

        public void run() {
            try {
                if (isBlocking) return;
                int ch = in.peek(0L);
                if (ch < -1) return;
                for (int i = 0; i < keys.length; i++) {
                    if (ch != keys[i] && keys[i] != '*') continue;
                    in.read();
                    event.actionPerformed(new ActionEvent(this, ActionEvent.ACTION_PERFORMED, Character.toChars(ch).toString()));
                    return;
                }
                if (ch > 32) isBlocking = true;
                else in.read();
            } catch (Exception e) {
                //e.printStackTrace();
            }
        }
    }
}