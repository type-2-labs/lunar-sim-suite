"""Loads an OmniLRS scene headless (ROS 2 mode), steps it, and saves three camera views with Replicator. A quick
check that the scene renders on a rented machine with no screen.

usage (from /workspace/omnilrs):  /isaac-sim/python.sh snapshot.py lunaryard_20m /workspace/snapshots"""
import sys
from pathlib import Path

env, out = sys.argv[1], Path(sys.argv[2])
sys.argv = sys.argv[:1]
from hydra import compose, initialize

import run as R
from src.environments_wrappers import startSim

with initialize(config_path="cfg", version_base="1.3"):
    cfg = compose(config_name="config", overrides=[f"environment={env}", "mode=ROS2", "rendering.renderer.headless=True"])
cfg = R.instantiateConfigs(R.omegaconfToDict(cfg))
SM, app = startSim(cfg)

import numpy as np
import omni.replicator.core as rep
from PIL import Image

out.mkdir(parents=True, exist_ok=True)
views = {"oblique": ((-2, -2, 3), (10, 10, 0)), "down": ((10, 10, 18), (10, 10.01, 0)), "low": ((10, 2, 0.8), (10, 12, 0))}
anns = {}
for k, (pos, at) in views.items():
    cam = rep.create.camera(position=pos, look_at=at)
    rp = rep.create.render_product(cam, (1280, 720))
    a = rep.AnnotatorRegistry.get_annotator("rgb")
    a.attach([rp])
    anns[k] = a
SM.world.reset()
SM.world.play()
for _ in range(120):
    SM.world.step(render=True)
rep.orchestrator.step(rt_subframes=32)
for k, a in anns.items():
    img = np.asarray(a.get_data())[..., :3]
    Image.fromarray(img).save(out / f"{env}_{k}.png")
    print("SNAP", k, round(float(img.mean()), 1), flush=True)
app.close()
