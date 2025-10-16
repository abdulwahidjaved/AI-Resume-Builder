from django.urls import path
from . import views

urlpatterns = [
    path("upload_resume/", views.upload_resume, name="upload_resume"),
    path("start_interview/", views.start_interview, name="start_interview"),
    path("answer/", views.answer_question, name="answer_question"),
    path("finish/", views.finish_evaluate, name="finish_evaluate"),
]