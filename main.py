from SpotiFLAC import SpotiFLAC
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import threading

app = Flask(__name__)
CORS(app)

# Job store
jobs = {}  # job_id -> {link, status, stop_flag, thread}
job_id_counter = 0
lock = threading.Lock()  # to safely increment job ids


@app.route('/', methods=['GET', 'POST'])
def index():
    global job_id_counter

    if request.method == "GET":
        return render_template('index.html')
    
    elif request.method == "POST":
        data = request.get_json()
        link = data.get('link')

        with lock:
            job_id = job_id_counter
            job_id_counter += 1

        stop_flag = threading.Event()
        jobs[job_id] = {
            "link": link,
            "status": "queued",
            "stop_flag": stop_flag,
            "thread": None
        }

        # start download in a thread
        t = threading.Thread(target=download, args=(job_id, link, stop_flag))
        jobs[job_id]["thread"] = t
        t.start()

        print(f"Received Spotify link: {link}, job_id: {job_id}")

        return jsonify({"message": "Download started", "job_id": job_id})


def download(job_id, link, stop_flag):
    try:
        jobs[job_id]["status"] = "downloading"

        # SpotiFLAC itself doesn't support mid-download canceling,
        # so this only stops between retries if loop is used
        SpotiFLAC(
            url=link,
            output_dir="./music",
            services=["tidal", "spoti", "youtube", "qobuz", "amazon"],
            filename_format="{year} - {album}/{track}. {title}",
            use_artist_subfolders=True,
            use_album_subfolders=True,
            loop=60*24
        )

        if stop_flag.is_set():
            jobs[job_id]["status"] = "cancelled"
        else:
            jobs[job_id]["status"] = "finished"

        print(f"Finished: {link}")

    except Exception as e:
        jobs[job_id]["status"] = "error"
        print(f"Error downloading {link}: {e}")


@app.route('/status')
def status():
    return jsonify({job_id: {"link": job["link"], "status": job["status"]} for job_id, job in jobs.items()})


@app.route('/cancel', methods=['POST'])
def cancel():
    data = request.get_json()
    job_id = data.get('job_id')
    job = jobs.get(job_id)
    if not job:
        return jsonify({"message": "Job not found"}), 404

    job["stop_flag"].set()
    print(f"Cancel requested for job_id: {job_id}")
    return jsonify({"message": "Cancel requested"})


def main():
    app.run(host='0.0.0.0', port=5000, debug=True)


if __name__ == "__main__":
    main()