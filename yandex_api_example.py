class YandexSchedule:

    def __init__(self, request):
        self.session = requests.Session()
        self.session.headers.update({
            'content-type': 'application/json',
            'Accept': 'application/json',
            'Authorization': settings.YANDEX_SCHEDULE_API_KEY
        })
        self.logger = request.logger
        self.request_counter = 0
        self.request_zero_counter_timestamp = datetime.datetime.now().timestamp()
        self.limit = 0
        self.max_limit = 300000

    def check_timer(self):
        self.limit += 1
        self.request_counter += 1
        if self.request_counter == settings.YANDEX_SCHEDULE_REQUESTS_PER_SECOND:
            time_sleep = 1 + self.request_zero_counter_timestamp - datetime.datetime.now().timestamp()
            if time_sleep > 0:
                time.sleep(time_sleep)
            self.request_counter = 0
            self.request_zero_counter_timestamp = datetime.datetime.now().timestamp()

    def get_train_schedule_data(self, station_from, station_to, date=None):
        self.check_timer()
        url = f"{settings.YANDEX_SCHEDULE_URL}?format=json&from={station_from}&to={station_to}&lang=ru_RU&limit=1000"
        if date is not None:
            url += f"&date={date}"
        # self.logger.info(url)

        response = self.session.request('GET', url, verify=False, timeout=15)
        data = response.json()
        return data

    def get_airport_schedule_data(self, station, offset=0):
        self.check_timer()
        url = (f"{settings.YANDEX_SCHEDULE_AIRPORT_URL}?"
               f"format=json&"
               f"station={station}&"
               f"transport_types=plane&"
               f"limit=1000")

        response = self.session.request('GET', url, verify=False, timeout=25)
        data = response.json()
        return data

    def get_thread_data(self, train_uid, date=None):
        self.check_timer()
        url = f"{settings.YANDEX_THREAD_URL}?uid={train_uid}"
        if date is not None:
            url += f'&date={date}'
        # self.logger.info(url)

        response = self.session.request('GET', url, verify=False, timeout=15)
        data = response.json()
        return data

    def __del__(self):
        self.session.close()

